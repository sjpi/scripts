## web scraper designed to extract email addresses and business names from a list of URLs
### !! Use only when and where you are given permission ##

import re
import random
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException, WebDriverException
from selenium.webdriver.common.by import By

# List of user agents to choose from
user_agents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
]

def create_driver(user_agent):
    options = Options()
    options.headless = True
    options.add_argument(f"user-agent={user_agent}")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-extensions")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    # Ensure the path to your ChromeDriver is correct
    driver = webdriver.Chrome(options=options)
    return driver

def scrape_emails_and_business(url):
    random.shuffle(user_agents)
    
    for user_agent in user_agents:
        driver = create_driver(user_agent)
        try:
            driver.get(url)
            time.sleep(3)  # Wait for page to load

            # Check if the page loaded successfully
            if driver.title:  # Simplistic check
                content = driver.page_source
                email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
                emails = re.findall(email_pattern, content)
                
                # Validate email format
                valid_emails = [email for email in emails if re.match(email_pattern, email)]
                
                # Extract business name using the provided XPath
                try:
                    business_name = driver.find_element(By.XPATH, '/html/body/div[1]/div/div/div/div[1]/div/div/div[3]/div[1]/div[1]/div/div/h1').text
                except NoSuchElementException:
                    business_name = "N/A"
                
                if valid_emails:
                    driver.quit()
                    return valid_emails, user_agent, business_name
                else:
                    print(f"Attempt with User Agent {user_agent} found no valid emails.")
        except WebDriverException as e:
            print(f"Attempt with User Agent {user_agent} encountered an error: {e}")
        finally:
            try:
                driver.quit()
            except WebDriverException as e:
                print(f"Error closing the driver: {e}")
    
    return [], None, None

def append_emails_to_file(url, emails, business_name, filename="found_emails.txt"):
    with open(filename, "a") as file:
        file.write(f"URL: {url}\n")
        file.write(f"Business Name: {business_name}\n")
        for email in emails:
            file.write(f"{email}\n")

# Function to read URLs from a text file
def read_urls_from_file(filename):
    with open(filename, "r") as file:
        return [line.strip() for line in file.readlines()]

# Read URLs from the text file
url_list = read_urls_from_file("urls.txt")

# Iterate over each URL and scrape emails
for url in url_list:
    print(f"\nScraping URL: {url}")
    
    # Number of attempts
    num_attempts = 1
    
    for i in range(num_attempts):
        print(f"\nAttempt {i+1}:")
        
        # Scrape emails and business name
        found_emails, user_agent_used, business_name = scrape_emails_and_business(url)
        
        # Print and save results
        if found_emails:
            print("Emails found:")
            for email in found_emails:
                print(email)
            append_emails_to_file(url, found_emails, business_name)
            break  # Exit the loop if emails are found
        else:
            print("No emails found or scraping was prevented.")
        
        if user_agent_used:
            print(f"User Agent used: {user_agent_used}")
        else:
            print("All User Agents failed to retrieve the webpage.")
