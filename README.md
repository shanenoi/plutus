# Plutus


<p align="center">
  <img src="./assets/plutus.jpeg" alt="Plutus" width="400" height="400">
</p>

Plutus is a data crawling project designed to fetch **SJC** gold price data from a specific website and store it in a database. The collected data can then be visualized using Grafana to generate charts and graphs. Additionally, historical data from the past 1 or 2 years can be obtained from another website.

## Getting Started

To use Plutus, follow the steps below:

### Prerequisites

- Ensure you have Node.js and npm installed on your machine.

### Installation

1. Clone the Plutus repository to your local machine.
2. Run `npm install` to install the required dependencies.

### Crawling New Data

To crawl new gold price data from the designated website and store it in the database, you need to set up a cron job to run the script at regular intervals.

1. Define a cron job to run the script every 30 minutes. Use the following command:

   ````
   */30 * * * * /path/cronjob.sh >> /path/logs 2>&1
   ```

   Replace `/path/cronjob.sh` with the actual path to the script.

### Crawling Historical Data

To crawl historical data from the past 1 or 2 years, follow these steps:

1. Run `npm install` to ensure all dependencies are installed.
2. Execute the following command:

   ````
   bash /path/crawl_data.sh
   ```

   Replace `/path/crawl_data.sh` with the actual path to the script.

3. The script will generate a file named `final.sql`.
4. Run the `final.sql` file to insert the crawled historical data into the database.

## Database Structure

The structure of the database used by Plutus will be provided at a later stage. Please refer to the documentation for details on the table schema and data organization.

> The Database Structure documentation will be updated with the actual structure once it becomes available.


## Grafana Dashboard

The configuration for the Grafana dashboard will be updated and provided at a later stage. It will include the necessary settings to connect to the Plutus database and visualize the gold price data.

> Please note that the Grafana dashboard configuration is currently being worked on and will be updated in the near future.


## Contributing

Contributions to Plutus are welcome! If you encounter any issues or have ideas for improvements, please feel free to submit pull requests or open issues on the project's repository.

## License

Plutus is released under the [MIT License](https://opensource.org/licenses/MIT).
