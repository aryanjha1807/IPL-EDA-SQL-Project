# 🏏 IPL 2025 SQL-Based Exploratory Data Analysis (EDA)

## 📌 Project Overview

This project involves a comprehensive exploratory analysis of the **IPL 2025 Season**, covering match-level, team-level, and player-level performance through **70+ unique SQL queries**.

The dataset was manually curated from scratch using Web-Scraping & Manual Data Entry. Data was stored and analyzed using **PostgreSQL**, and final insights were exported for visualizations.

---

## 🛠️ Tools Used

**PostgreSQL** – Querying and data analysis  
**Excel** – Data collection and preprocessing  
**Python** – For importing Excel into PostgreSQL  
**VS Code** – Query writing and Markdown reporting

---

## 🧠 EDA Objectives Covered

✔️ Top performers (batters, bowlers, strike rate, economy)  
✔️ Match insights (win margins, impact player contributions)  
✔️ Team-wise performance breakdown  
✔️ Over-wise scoring, powerplay efficiency  
✔️ Toss impact analysis  
✔️ Head-to-head records  
✔️ Positional analysis of shots by area

---

## 🗃️ Folder Structure

```
IPL-EDA-SQL-Project/
│
├── IPL-Datasets/ # Cleaned Excel → Sample CSV sheets
├── SQL/ # All 70+ Queries in organized .sql files
├── Outputs/ # CSV outputs from queries
├── Visuals/ # Visualizations (Coming-Soon)
└── README.md
```

---

## 📁 Datasets Included

| File                   | Description                      |
|------------------------|----------------------------------|
| `IPL_MainSheet.csv`    | Match-wise summary of 74 matches |
| `IPL_Batters.csv`      | Ball-by-ball player stats        |
| `IPL_Bowlers.csv`      | Over-by-over bowling stats       |
| `IPL_Partnerships.csv` | Partnerships in each innings     |
| `IPL_Overwise.csv`     | Over-by-over score data          |
| `Teamwise_*.csv`       | Team-specific breakdowns         |

---

## 💡 Sample SQL Query

```sql
-- Top 10 Batters with Highest Runs
SELECT
    batter_name as "Batter Name",
    SUM(runs_scored) AS "Total Runs"
FROM ipl_batters
GROUP BY "Batter Name"
ORDER BY "Total Runs" DESC
LIMIT 10;
```

---

## 📊 Key Insights (Few Highlights)

* Teams winning Toss, Won the Match **{58%}** of the Times
* Sai Sudharsan leads leads the Top Run-Scorer list with **{759-Runs}**
* Prasidh Krishna picked leads the Top Wicket-Taker list with **{25-Wickets}**
* Bowling First Team had **52%** Win Rate comparatively Batting First which had **48%** Win Rate.
* IPL-2025 Recorded the Highest Score by Sunrisers Hyderabad (SRH) **{286}** *[SRH v/s PBKS in Match-2]*
* Mumbai Indians has had the Least Economy Rate Throughout Season **{8.87}**

➡️ And Many More Exciting Results & Analysis available inside the /Outputs/ folder.

---

## ✍️ Author
Name: Aryan Jha  
[Mail](aryanjhavsp0802@gmail.com) [LinkedIn](https://linkedin.com/in/aryan-jha-50b12329b) [YouTube](https://youtube.com/@ProgramWithAryan)  

## License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.