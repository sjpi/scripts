# Email and Business Name Scraper

This Python script uses Selenium to scrape email addresses and business names from a list of URLs. It rotates user agents for each attempt to avoid detection and saves the results to a file.

---

## Requirements

1. **Python Libraries**:
   - `selenium`
   - `re`
   - Install Selenium:
     ```bash
     pip install selenium
     ```

2. **ChromeDriver**:
   - Ensure ChromeDriver is installed and added to the system's PATH.
   - Download ChromeDriver: [https://sites.google.com/a/chromium.org/chromedriver/](https://sites.google.com/a/chromium.org/chromedriver/)

3. **Input File**:
   - Create a file named `urls.txt` containing the list of URLs to scrape. Each URL should be on a new line.

---

## How to Use

1. **Prepare the Input File**:
   - Add the URLs to be scraped in a file named `urls.txt` in the same directory as the script.

   Example `urls.txt`:
   ```
   https://example.com
   https://anotherexample.com
   ```

2. **Run the Script**:
   - Execute the script in a Python environment:
     ```bash
     python scraper.py
     ```

     ## Notes

- Ensure the XPath used for extracting the business name matches the structure of the target webpages.
- Use a valid version of ChromeDriver compatible with your Chrome browser.
- Adjust the delay (`time.sleep`) in the script if pages are taking longer to load.

---

## Troubleshooting

- **Error: WebDriverException**:
  - Ensure ChromeDriver is correctly installed and in your PATH.
- **No emails or business names found**:
  - Verify the target webpage structure matches the script's XPath and email regex.
- **Timeouts**:
  - Increase the sleep duration. Check useragents for blocking, check IP reputation?
