Based on the performance of the original strategy submitted on 21st March 2023, we have made some essential optimizations.
The "Final Modified Code" folder represents our final optimized trading strategy.
The optimization contains five parts:

(1) Data Analysis

This part contains three of our data analysis and figure drawing approaches.

1. Data Statistics for RSRS
This part contains rsrs slop and rsrs z-score statistic distribution chart, as well as statistics data.
Open "statistics.R", select all the codes and run. The diagrams will be displayed in RStudio.
Put new csv files in the default path to if you want to test other stock series. Remember to reference the data if it is not in the default path.

2. K-plot
This k-plot aims to show the overall trend of the two simple moving averages and the MACD at different series. 
Open "statistics.R", select all the codes and run. The diagrams will be displayed in RStudio.
Put new csv files in the default path to if you want to test other stock series. Remember to reference the data if it is not in the default path.

3. Stock Trend Analysis
This part conatins the drawing of stock trend, multiple diagrams displaying the stock's characteristics and the classical decomposition model diagram.
Open "statistics.R", select all the codes and run. The diagrams will be displayed in RStudio.
Put new csv files in the default path to if you want to test other stock series. Remember to reference the data if it is not in the default path.


(2) Parameter Optimization
Parameter optimization uses for loop to find the optimised performing parameters for a multi-factor strategy.
Open "main.R", select all the codes and run. A "Mydata.csv" file will be generated in the default path. 
This csv file record "x - thr006 value", "y - obday value" and "z - corresponding P/D Ratio".
This parameter optimization is only suitable for strategy file "combination2.R"


(3) Position Visualization
Position visualization is designed to visualize the changes in trading positions for each series to determine whether the trade satisfied the desired logic.
Open "main.R", select all the codes and run. The position diagrams .png files will be generated in the default path.


(4) Final Modified Code
We have indicated our strategy's shortcomings in the final report and have tried our best to deal with them.
This contains our final modeified strategy "team7.R", which can be found in "strategies" folder.
It is worth noticing that the parameter set-up has been completed in "example_strategies.R"
Open "main.R", select all the codes and run. 


(5) Robustness Testing
We extend our testing data, adding another dataset called "11.csv" in Part 1 data. It aims to clarify that our strategy works in other dataset.
Open "main.R", select all the codes and run.


University of Liverpool - 
3rd May, 2023

_________________________________________________________________________________________________________________________

"Team7.R" is the final strategy code submitted on 21st March, 2023.

The strategy contains a paramater vector in the very front part of the file.
To Initialize, please do the following steps.

1. Decompress original framework.
2. Copy the strategy file "Team7.R" to the "strategies" folder.
3. Open the strategy file, rename "params" as "team7".
4. Cut the whole paramater to vector "example_params" in file "example_strategies.R".
5. Add a strategy name "team7" to vector "example_strategies" in file "example_strategies.R".
6. Change the strategy name to "team7" in the row11 of "main.R".
7. You shall successfully run the strategy.

Note: The default stock data is Part 1. If you wish to change the stock data, you can modify it in row8 of "main.R"
To skip the initialization part, you can also directly run the code in the "Testing Framework", where everything has been set up.

University of Liverpool - 
21st March, 2023
