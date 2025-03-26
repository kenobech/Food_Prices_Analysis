# Food Prices Analysis in Kenya

## Overview
This project analyzes food price trends in Kenya using a dataset provided by the World Food Programme (WFP). The analysis aims to uncover insights into price fluctuations in different locations across Kenya and their potential causes. This project demonstrates expertise in SQL for data analysis and Git for version control.

---

## Objectives
The primary objectives of this project are:
1. To analyze historical food price trends in Kenya.
2. To identify regional price disparities and their potential causes.
3. To highlight commodities with the highest price volatility.
4. To provide actionable insights for policymakers, farmers, businesses, and researchers.

## Table of Contents
1. [Dataset](#dataset)
2. [SQL Analysis](#sql-analysis)
3. [How to Run](#how-to-run)
4. [Results](#results)
5. [Tools Used](#tools-used)
6. [Folder Structure](#folder-structure)
7. [Documentation](#documentation)
8. [Contributing](#contributing)
9. [License](#license)
10. [Author](#author)

---

## Dataset
- **File**: `wfp_food_prices_ken.csv`
- **Source**: World Food Programme (WFP)
- **Description**: Contains historical food price data for various commodities in Kenya, including prices, regions, and dates.

---

## SQL Analysis
The SQL script `SQL_Analysis_Food_Prices_Kenya_v2.sql` performs the following:
1. Cleans and preprocesses the data to handle missing or inconsistent values.
2. Analyzes price trends over time to identify patterns and anomalies.
3. Identifies regional price variations to highlight disparities across locations.
4. Highlights commodities with the highest price volatility to understand market dynamics.
5. Provides additional insights into seasonal trends and correlations.

The SQL script is optimized for performance and includes detailed comments for clarity.

## Prerequisites
Before running this project, ensure you have the following:
1. A SQL database management system (e.g., MySQL, PostgreSQL, or SQL Server). This script is for Ms SQL Server.
2. A text editor or IDE for SQL scripts (e.g., VS Code, DBeaver). In this case, the text editor I used is VS Code.
3. Git installed on your local machine for version control.
4. Basic knowledge of SQL and Git.

---

## How to Run
1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/kenobech/Food_Prices_Analysis.git
   ```

2. Load the dataset into your preferred SQL database (e.g., MySQL, PostgreSQL, SQL Server).

3. Execute the SQL script `SQL_Analysis_Food_Prices_Kenya_v2.sql` in your database.

4. Review the results to gain insights into food price trends.

---

## Results
The analysis provides:

1. Average prices for key commodities over time.

2. Regional price comparisons to identify disparities.

3. Insights into seasonal price changes and trends.

4. Volatility analysis for commodities with fluctuating prices.

---

## Tools Used

1. SQL: For data cleaning, analysis, and querying.

2. Git: For version control and collaboration.

3. CSV: For data storage and input.

---

## Folder Structure
```
Food_Prices_Analysis/
│
├── SQL_Analysis_Food_Prices_Kenya_v2.sql  # Updated SQL analysis script
├── wfp_food_prices_ken.csv               # Dataset
├── documentation.md                      # Detailed project documentation
├── README.md                             # Project overview
```

---

## Documentation
For detailed information about the project, including methodology, assumptions, and additional insights, refer to the [documentation.md](documentation.md) file.

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.

2. Create a new branch for your feature or bug fix:
git checkout -b feature-name

3. Commit your preffered changes
git commit -m "Add feature-name"

4. Push to your branch:
git push origin feature-name

5. Open a pull request

---

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Author
This project was created by Ken Obech as part of a portfolio showcasing expertise in SQL, data analysis, and Git.


---

### Key Additions:
1. **Table of Contents**: Improves navigation for larger files.
2. **Contributing**: Encourages collaboration and outlines the process for contributing.
3. **License**: Adds a professional touch and clarifies usage rights.
4. **Git Commands**: Demonstrates Git expertise by including commands for cloning and contributing.

