use std::error::Error;
use std::process::Command;
use thirtyfour::prelude::*;
use tokio::time::{sleep, Duration};
use clap::Parser;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args
{
    #[arg(short, long)]
    role_name: Vec<String>,
    
    #[arg(short, long, default_value = "john.battye@ipfin.co.uk")]
    email: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error + Send + Sync>> {
    let args = Args::parse();

    for role_name in &args.role_name {
        println!("{:?}", role_name);
    }

    let mut process = match Command::new("msedgedriver")
        .args(&["--port=54950"])
        .spawn() {
        Ok(process) => process,
        Err(err) => panic!("Running process error: {}", err),
    };

    let caps = DesiredCapabilities::edge();
    let driver = WebDriver::new("http://localhost:54950", caps).await?;
    driver.goto("https://entra.microsoft.com/#view/Microsoft_Azure_PIMCommon/GroupRoleBlade/resourceId//subjectId//isInternalCall~/true?Microsoft_AAD_IAM_legacyAADRedirect=true/").await?;
    
    // Wait for initial page load
    sleep(Duration::from_millis(3000)).await;
    
    // Check for account selection page and try to select the correct account
    if let Ok(account_tiles) = driver.query(By::ClassName("table")).first().await {
        println!("Account selection page detected");
        
        // Look for account tiles that might contain the email
        if let Ok(tiles) = account_tiles.query(By::ClassName("table-row")).all_from_selector().await {
            println!("Found {} account tiles", tiles.len());
            
            for tile in tiles {
                if let Ok(email_element) = tile.query(By::Tag("div")).first().await {
                    if let Ok(email_text) = email_element.text().await {
                        println!("Found account: {}", email_text);
                        
                        // Try to match email (case insensitive)
                        if email_text.to_lowercase().contains(&args.email.to_lowercase()) {
                            println!("Selecting account: {}", email_text);
                            tile.click().await?;
                            // Wait for navigation after account selection
                            sleep(Duration::from_millis(5000)).await;
                            break;
                        }
                    }
                }
            }
        }
        
        // If we're still on the account selection page, select the first account as fallback
        if let Ok(_) = driver.query(By::ClassName("table")).first().await {
            println!("Still on account selection page, selecting first account as fallback");
            if let Ok(first_tile) = driver.query(By::ClassName("table-row")).first().await {
                first_tile.click().await?;
                sleep(Duration::from_millis(5000)).await;
            }
        }
    }
    
    // Wait for the roles page to fully load
    println!("Waiting for roles page to load...");
    sleep(Duration::from_millis(5000)).await;
    
    // Try to locate the roles table
    let mut attempts = 0;
    let max_attempts = 5;
    let mut roles_table_tbody = None;
    
    while attempts < max_attempts {
        if let Ok(table) = driver.query(By::ClassName("azc-grid-groupdata")).first().await {
            roles_table_tbody = Some(table);
            break;
        }
        println!("Waiting for roles table to appear (attempt {}/{})", attempts + 1, max_attempts);
        sleep(Duration::from_millis(3000)).await;
        attempts += 1;
    }
    
    let roles_table_tbody = roles_table_tbody.ok_or("Roles table not found after multiple attempts")?;
    let role_rows = roles_table_tbody.query(By::Tag("tr")).all_from_selector().await?;
    
    for row in role_rows {
        let columns = row.query(By::Tag("td")).all_from_selector().await?;
        let role_description_column = &columns[1];
        let cell_content_div = role_description_column.find(By::Tag("div")).await?;
        let viva_control_div = cell_content_div.find(By::Tag("div")).await?;
        let content_div = viva_control_div.find(By::Tag("div")).await?;
        let content = content_div.text().await?;

        println!("{:?}", content);
        if args.role_name.contains(&content) {
            let activate_column = &columns[5];
            let activate_link = activate_column.query(By::Tag("a")).first().await?;
            activate_link.click().await?;

            // Wait for the activation form to appear with manual timeout
            let mut slider = None;
            for _ in 0..10 { // 10 attempts = 10 seconds max
                if let Ok(s) = driver.query(By::ClassName("fxc-slider")).first().await {
                    slider = Some(s);
                    break;
                }
                sleep(Duration::from_millis(1000)).await;
            }
            
            let slider = slider.ok_or("Activation form not found after 10 seconds")?;
            let tab_pane = slider.parent().await?;

            let tab_pane_divs = tab_pane.query(By::Tag("div")).all_from_selector().await?;

            for div in tab_pane_divs {
                let data_formelement = div.attr("data-formelement").await?;
                match data_formelement {
                    Some(str) => match str.as_str() {
                        "pcControl: ticketSystemTextBox" => {
                            let input = div.query(By::Tag("input")).first().await?;
                            input.wait_until().enabled().await?;
                            input.send_keys("1").await?;
                        },
                        "pcControl: ticketNumberTextBox" => {
                            let input = div.query(By::Tag("input")).first().await?;
                            input.wait_until().enabled().await?;
                            input.send_keys("1").await?;
                        },
                         "pcControl: comments" => {
                            let input = div.query(By::Tag("textarea")).first().await?;
                            input.wait_until().enabled().await?;
                            input.send_keys("1").await?;
                        },
                        _ => {}
                    }
                    _ => continue
                }
            }

            let container = tab_pane.parent().await?.parent().await?.parent().await?.parent().await?.parent().await?;
            println!("{:?}", container.attr("class").await?);
            let buttons = container.query(By::ClassName("fxs-button")).all_from_selector().await?;
            for button in buttons {
                println!("{:?}", button.inner_html().await?);

                let title_option = button.attr("title").await?;
                
                if let Some(title) = title_option {
                    if title == "Activate" {
                        button.wait_until().enabled().await?;
                        button.click().await?;
                        sleep(Duration::from_millis(10000)).await;
                        break;
                    }
                }
            }
        }
    }

    driver.quit().await?;
    let _ = process.kill();
    Ok(())
}