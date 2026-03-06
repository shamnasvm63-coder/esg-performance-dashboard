# ============================================================
# PROJECT 1: ESG Performance Dashboard
# Author: Shamnas Valangauparambil Mohammedali
# Tools: R, Shiny, ggplot2, dplyr, plotly
# Purpose: Interactive ESG analysis dashboard for portfolio
# Data: Public ESG scores & CO2 emissions for global companies
# ============================================================

# ── PACKAGES ────────────────────────────────────────────────
# Run this once in console if not installed:
# install.packages(c("shiny","shinydashboard","ggplot2","dplyr","plotly","DT","scales"))

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(plotly)
library(DT)
library(scales)

# ── LOAD DATA ───────────────────────────────────────────────
esg_data <- read.csv("esg_data.csv", stringsAsFactors = FALSE)

# Derived fields
esg_data <- esg_data %>%
  mutate(
    CO2_per_Revenue = round(CO2_Emissions_MtCO2 / Revenue_BillionUSD, 3),
    CO2_per_Employee = round((CO2_Emissions_MtCO2 * 1e6) / Employees, 1),
    ESG_Rating = case_when(
      ESG_Total >= 75 ~ "AAA — Leader",
      ESG_Total >= 65 ~ "AA — Advanced",
      ESG_Total >= 55 ~ "A — Good",
      ESG_Total >= 45 ~ "BBB — Average",
      TRUE            ~ "BB — Laggard"
    )
  )

latest <- esg_data %>% filter(Year == 2023)
sectors <- sort(unique(esg_data$Sector))
countries <- sort(unique(esg_data$Country))
companies_2023 <- sort(unique(latest$Company))

# ── COLOUR PALETTE ──────────────────────────────────────────
NAVY   <- "#1B3A5C"
ACCENT <- "#2E86AB"
GREEN  <- "#27AE60"
AMBER  <- "#F39C12"
RED    <- "#E74C3C"
LGRAY  <- "#F5F7FA"

rating_colors <- c(
  "AAA — Leader"   = "#27AE60",
  "AA — Advanced"  = "#2E86AB",
  "A — Good"       = "#3498DB",
  "BBB — Average"  = "#F39C12",
  "BB — Laggard"   = "#E74C3C"
)

# ── UI ──────────────────────────────────────────────────────
ui <- dashboardPage(
  skin = "blue",

  # Header
  dashboardHeader(
    title = tags$span(
      style = "font-weight:700; font-size:15px;",
      "ESG Performance Dashboard"
    ),
    titleWidth = 280
  ),

  # Sidebar
  dashboardSidebar(
    width = 280,
    tags$div(
      style = "padding: 12px 15px 0; color:#aaa; font-size:11px; text-transform:uppercase; letter-spacing:1px;",
      "Filters"
    ),
    selectInput("sector_filter", "Sector",
                choices = c("All Sectors", sectors),
                selected = "All Sectors"),
    selectInput("country_filter", "Country",
                choices = c("All Countries", countries),
                selected = "All Countries"),
    sliderInput("year_range", "Year Range",
                min = 2021, max = 2023,
                value = c(2021, 2023),
                step = 1, sep = ""),
    hr(style = "border-color:#3c5a78;"),
    tags$div(
      style = "padding: 12px 15px 0; color:#aaa; font-size:11px; text-transform:uppercase; letter-spacing:1px;",
      "Compare Companies"
    ),
    selectInput("company_a", "Company A",
                choices = companies_2023,
                selected = "Siemens"),
    selectInput("company_b", "Company B",
                choices = companies_2023,
                selected = "Shell"),
    hr(style = "border-color:#3c5a78;"),
    tags$div(
      style = "padding: 10px 15px; color:#8ab4cc; font-size:11px;",
      tags$b("About this project:"), tags$br(),
      "Built in R (Shiny, ggplot2, plotly) using publicly available ESG & emissions data for 30 global companies, 2021–2023.",
      tags$br(), tags$br(),
      tags$b("Author:"), " Shamnas V.M", tags$br(),
      tags$b("MSc"), " Transition Management, JLU Giessen"
    )
  ),

  # Body
  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper { background-color: #F5F7FA; }
      .box { border-top: 3px solid #2E86AB; border-radius: 6px; }
      .small-box { border-radius: 8px; }
      .info-box { border-radius: 8px; }
      h3.box-title { font-weight: 700; color: #1B3A5C; }
      .nav-tabs-custom > .nav-tabs > li.active { border-top-color: #2E86AB; }
    "))),

    # ── TAB 1: Overview ────────────────────────────────────
    tabsetPanel(
      id = "tabs",

      tabPanel("📊 Overview",
        br(),
        # KPI boxes
        fluidRow(
          valueBoxOutput("vbox_companies", width = 3),
          valueBoxOutput("vbox_avg_esg",   width = 3),
          valueBoxOutput("vbox_avg_co2",   width = 3),
          valueBoxOutput("vbox_leaders",   width = 3)
        ),
        fluidRow(
          # ESG bar chart
          box(
            title = "ESG Total Score by Company (2023)", width = 8,
            status = "primary", solidHeader = FALSE,
            plotlyOutput("plot_esg_bar", height = "380px")
          ),
          # Rating donut
          box(
            title = "ESG Rating Distribution", width = 4,
            status = "primary", solidHeader = FALSE,
            plotlyOutput("plot_rating_donut", height = "380px")
          )
        ),
        fluidRow(
          # E vs S vs G radar-style comparison
          box(
            title = "Environmental vs Social vs Governance Scores", width = 12,
            status = "primary", solidHeader = FALSE,
            plotlyOutput("plot_esg_components", height = "340px")
          )
        )
      ),

      # ── TAB 2: CO2 Emissions ────────────────────────────
      tabPanel("🌍 CO2 Emissions",
        br(),
        fluidRow(
          box(
            title = "CO2 Emissions vs ESG Score (2023) — Bubble = Revenue", width = 8,
            status = "primary",
            plotlyOutput("plot_co2_esg_bubble", height = "400px")
          ),
          box(
            title = "Top 10 Emitters (2023)", width = 4,
            status = "primary",
            plotlyOutput("plot_top_emitters", height = "400px")
          )
        ),
        fluidRow(
          box(
            title = "CO2 Intensity: Emissions per $1B Revenue by Sector", width = 6,
            status = "primary",
            plotlyOutput("plot_co2_intensity", height = "320px")
          ),
          box(
            title = "Emissions per Employee by Company (2023)", width = 6,
            status = "primary",
            plotlyOutput("plot_co2_employee", height = "320px")
          )
        )
      ),

      # ── TAB 3: Trends ───────────────────────────────────
      tabPanel("📈 Trends 2021–2023",
        br(),
        fluidRow(
          box(
            title = "ESG Score Trend Over Time", width = 6,
            status = "primary",
            plotlyOutput("plot_esg_trend", height = "360px")
          ),
          box(
            title = "CO2 Emissions Trend Over Time", width = 6,
            status = "primary",
            plotlyOutput("plot_co2_trend", height = "360px")
          )
        ),
        fluidRow(
          box(
            title = "Average ESG Score Change: 2021 → 2023 by Sector", width = 12,
            status = "primary",
            plotlyOutput("plot_sector_change", height = "300px")
          )
        )
      ),

      # ── TAB 4: Company Compare ──────────────────────────
      tabPanel("🔍 Compare Companies",
        br(),
        fluidRow(
          box(
            title = "ESG Pillar Comparison (E / S / G)", width = 6,
            status = "primary",
            plotlyOutput("plot_compare_pillars", height = "380px")
          ),
          box(
            title = "Key Metrics Comparison", width = 6,
            status = "primary",
            plotlyOutput("plot_compare_bar", height = "380px")
          )
        ),
        fluidRow(
          box(
            title = "Summary Table", width = 12,
            status = "primary",
            DTOutput("table_compare")
          )
        )
      ),

      # ── TAB 5: Data Table ───────────────────────────────
      tabPanel("📋 Full Data",
        br(),
        fluidRow(
          box(
            title = "Complete ESG Dataset", width = 12,
            status = "primary",
            DTOutput("full_table")
          )
        )
      )
    )
  )
)

# ── SERVER ──────────────────────────────────────────────────
server <- function(input, output, session) {

  # Reactive filtered data
  filtered <- reactive({
    df <- esg_data %>%
      filter(Year >= input$year_range[1], Year <= input$year_range[2])
    if (input$sector_filter  != "All Sectors")   df <- df %>% filter(Sector  == input$sector_filter)
    if (input$country_filter != "All Countries") df <- df %>% filter(Country == input$country_filter)
    df
  })

  filtered_2023 <- reactive({
    filtered() %>% filter(Year == 2023)
  })

  # ── KPI BOXES ─────────────────────────────────────────
  output$vbox_companies <- renderValueBox({
    valueBox(nrow(filtered_2023()), "Companies Analysed",
             icon = icon("building"), color = "blue")
  })

  output$vbox_avg_esg <- renderValueBox({
    val <- round(mean(filtered_2023()$ESG_Total, na.rm = TRUE), 1)
    valueBox(val, "Avg ESG Score (2023)",
             icon = icon("leaf"), color = "green")
  })

  output$vbox_avg_co2 <- renderValueBox({
    val <- round(sum(filtered_2023()$CO2_Emissions_MtCO2, na.rm = TRUE), 0)
    valueBox(paste0(val, " Mt"), "Total CO2 (2023)",
             icon = icon("cloud"), color = "orange")
  })

  output$vbox_leaders <- renderValueBox({
    val <- filtered_2023() %>% filter(ESG_Rating %in% c("AAA — Leader", "AA — Advanced")) %>% nrow()
    valueBox(val, "ESG Leaders (AA+)",
             icon = icon("star"), color = "purple")
  })

  # ── OVERVIEW CHARTS ───────────────────────────────────

  # ESG bar chart sorted
  output$plot_esg_bar <- renderPlotly({
    df <- filtered_2023() %>% arrange(ESG_Total) %>%
      mutate(Company = factor(Company, levels = Company))

    p <- ggplot(df, aes(x = Company, y = ESG_Total, fill = ESG_Rating,
                        text = paste0("<b>", Company, "</b><br>",
                                      "Sector: ", Sector, "<br>",
                                      "ESG Score: ", ESG_Total, "<br>",
                                      "Rating: ", ESG_Rating))) +
      geom_col(width = 0.7) +
      scale_fill_manual(values = rating_colors) +
      coord_flip() +
      geom_hline(yintercept = 65, linetype = "dashed", color = NAVY, alpha = 0.5) +
      annotate("text", x = 1, y = 66, label = "Threshold: 65", size = 3, hjust = 0, color = NAVY) +
      labs(x = NULL, y = "ESG Total Score (0–100)", fill = "Rating") +
      theme_minimal(base_size = 12) +
      theme(legend.position = "bottom",
            panel.grid.minor = element_blank(),
            axis.text.y = element_text(size = 10))

    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })

  # Rating donut
  output$plot_rating_donut <- renderPlotly({
    df <- filtered_2023() %>%
      count(ESG_Rating) %>%
      arrange(desc(n))

    plot_ly(df, labels = ~ESG_Rating, values = ~n, type = "pie",
            hole = 0.5,
            marker = list(colors = unname(rating_colors[df$ESG_Rating])),
            textinfo = "label+percent",
            hovertemplate = "<b>%{label}</b><br>Companies: %{value}<extra></extra>") %>%
      layout(showlegend = FALSE,
             annotations = list(text = "ESG<br>Ratings", x = 0.5, y = 0.5,
                                font = list(size = 14), showarrow = FALSE))
  })

  # E vs S vs G components
  output$plot_esg_components <- renderPlotly({
    df <- filtered_2023() %>%
      select(Company, Sector, Environmental_Score, Social_Score, Governance_Score) %>%
      tidyr::pivot_longer(cols = c(Environmental_Score, Social_Score, Governance_Score),
                          names_to = "Pillar", values_to = "Score") %>%
      mutate(Pillar = gsub("_Score", "", Pillar))

    p <- ggplot(df, aes(x = reorder(Company, Score), y = Score, fill = Pillar,
                        text = paste0(Company, "<br>", Pillar, ": ", Score))) +
      geom_col(position = "dodge", width = 0.7) +
      coord_flip() +
      scale_fill_manual(values = c("Environmental" = GREEN, "Social" = ACCENT, "Governance" = NAVY)) +
      labs(x = NULL, y = "Score (0–100)", fill = "ESG Pillar") +
      theme_minimal(base_size = 11) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", y = -0.15))
  })

  # ── CO2 CHARTS ────────────────────────────────────────

  output$plot_co2_esg_bubble <- renderPlotly({
    df <- filtered_2023()
    p <- ggplot(df, aes(x = ESG_Total, y = CO2_Emissions_MtCO2,
                        size = Revenue_BillionUSD, color = Sector,
                        text = paste0("<b>", Company, "</b><br>",
                                      "ESG Score: ", ESG_Total, "<br>",
                                      "CO2: ", CO2_Emissions_MtCO2, " Mt<br>",
                                      "Revenue: $", Revenue_BillionUSD, "B<br>",
                                      "Sector: ", Sector))) +
      geom_point(alpha = 0.75) +
      scale_size_continuous(range = c(4, 20), guide = "none") +
      geom_smooth(aes(group = 1), method = "lm", se = TRUE,
                  color = NAVY, fill = LGRAY, linetype = "dashed", linewidth = 0.8) +
      scale_y_log10(labels = comma) +
      labs(x = "ESG Total Score", y = "CO2 Emissions (Mt, log scale)", color = "Sector") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })

  output$plot_top_emitters <- renderPlotly({
    df <- filtered_2023() %>%
      arrange(desc(CO2_Emissions_MtCO2)) %>%
      head(10) %>%
      mutate(Company = factor(Company, levels = rev(Company)))

    p <- ggplot(df, aes(x = Company, y = CO2_Emissions_MtCO2, fill = Sector,
                        text = paste0(Company, ": ", CO2_Emissions_MtCO2, " MtCO2"))) +
      geom_col(width = 0.7) +
      coord_flip() +
      labs(x = NULL, y = "CO2 Emissions (MtCO2)", fill = "Sector") +
      theme_minimal(base_size = 11) +
      theme(legend.position = "none", panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text")
  })

  output$plot_co2_intensity <- renderPlotly({
    df <- filtered_2023() %>%
      group_by(Sector) %>%
      summarise(Avg_Intensity = round(mean(CO2_per_Revenue, na.rm = TRUE), 3)) %>%
      arrange(Avg_Intensity)

    p <- ggplot(df, aes(x = reorder(Sector, Avg_Intensity), y = Avg_Intensity,
                        fill = Avg_Intensity,
                        text = paste0(Sector, ": ", Avg_Intensity, " MtCO2/$B"))) +
      geom_col(width = 0.7) +
      scale_fill_gradient(low = GREEN, high = RED, guide = "none") +
      coord_flip() +
      labs(x = NULL, y = "CO2 per $1B Revenue (MtCO2)") +
      theme_minimal(base_size = 11) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text")
  })

  output$plot_co2_employee <- renderPlotly({
    df <- filtered_2023() %>%
      arrange(desc(CO2_per_Employee)) %>%
      mutate(Company = factor(Company, levels = rev(Company)))

    p <- ggplot(df, aes(x = Company, y = CO2_per_Employee,
                        fill = Sector,
                        text = paste0(Company, "<br>CO2/employee: ",
                                      format(CO2_per_Employee, big.mark = ","), " tCO2"))) +
      geom_col(width = 0.7) +
      coord_flip() +
      labs(x = NULL, y = "tCO2 per Employee") +
      theme_minimal(base_size = 10) +
      theme(legend.position = "none", panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text")
  })

  # ── TREND CHARTS ──────────────────────────────────────

  output$plot_esg_trend <- renderPlotly({
    df <- filtered() %>%
      group_by(Company, Year) %>%
      summarise(ESG_Total = mean(ESG_Total), .groups = "drop")

    p <- ggplot(df, aes(x = Year, y = ESG_Total, color = Company, group = Company,
                        text = paste0(Company, " (", Year, "): ", ESG_Total))) +
      geom_line(linewidth = 1) +
      geom_point(size = 2.5) +
      scale_x_continuous(breaks = 2021:2023) +
      labs(x = "Year", y = "ESG Total Score", color = "Company") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })

  output$plot_co2_trend <- renderPlotly({
    df <- filtered() %>%
      group_by(Company, Year) %>%
      summarise(CO2 = sum(CO2_Emissions_MtCO2), .groups = "drop")

    p <- ggplot(df, aes(x = Year, y = CO2, color = Company, group = Company,
                        text = paste0(Company, " (", Year, "): ", CO2, " Mt"))) +
      geom_line(linewidth = 1) +
      geom_point(size = 2.5) +
      scale_x_continuous(breaks = 2021:2023) +
      labs(x = "Year", y = "CO2 Emissions (MtCO2)", color = "Company") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", y = -0.2))
  })

  output$plot_sector_change <- renderPlotly({
    df_21 <- esg_data %>% filter(Year == 2021) %>%
      group_by(Sector) %>% summarise(esg_2021 = mean(ESG_Total), .groups = "drop")
    df_23 <- esg_data %>% filter(Year == 2023) %>%
      group_by(Sector) %>% summarise(esg_2023 = mean(ESG_Total), .groups = "drop")
    df <- left_join(df_21, df_23, by = "Sector") %>%
      mutate(Change = round(esg_2023 - esg_2021, 1),
             Direction = ifelse(Change >= 0, "Improved", "Declined"))

    p <- ggplot(df, aes(x = reorder(Sector, Change), y = Change,
                        fill = Direction,
                        text = paste0(Sector, ": ", ifelse(Change > 0, "+", ""), Change, " pts"))) +
      geom_col(width = 0.65) +
      scale_fill_manual(values = c("Improved" = GREEN, "Declined" = RED)) +
      coord_flip() +
      geom_hline(yintercept = 0, color = NAVY) +
      labs(x = NULL, y = "ESG Score Change (2021 → 2023)", fill = "") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text")
  })

  # ── COMPARE CHARTS ────────────────────────────────────

  output$plot_compare_pillars <- renderPlotly({
    df <- esg_data %>%
      filter(Year == 2023, Company %in% c(input$company_a, input$company_b)) %>%
      select(Company, Environmental_Score, Social_Score, Governance_Score) %>%
      tidyr::pivot_longer(-Company, names_to = "Pillar", values_to = "Score") %>%
      mutate(Pillar = gsub("_Score", "", Pillar))

    p <- ggplot(df, aes(x = Pillar, y = Score, fill = Company,
                        text = paste0(Company, " — ", Pillar, ": ", Score))) +
      geom_col(position = "dodge", width = 0.6) +
      scale_fill_manual(values = c(ACCENT, AMBER)) +
      labs(x = NULL, y = "Score (0–100)", fill = "Company") +
      ylim(0, 100) +
      theme_minimal(base_size = 13) +
      theme(panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text")
  })

  output$plot_compare_bar <- renderPlotly({
    df <- esg_data %>%
      filter(Year == 2023, Company %in% c(input$company_a, input$company_b)) %>%
      select(Company, ESG_Total, CO2_Emissions_MtCO2, CO2_per_Revenue) %>%
      tidyr::pivot_longer(-Company, names_to = "Metric", values_to = "Value") %>%
      mutate(Metric = case_when(
        Metric == "ESG_Total" ~ "ESG Total Score",
        Metric == "CO2_Emissions_MtCO2" ~ "CO2 (MtCO2)",
        Metric == "CO2_per_Revenue" ~ "CO2 Intensity (Mt/$B)"
      ))

    p <- ggplot(df, aes(x = Metric, y = Value, fill = Company,
                        text = paste0(Company, " — ", Metric, ": ", round(Value, 2)))) +
      geom_col(position = "dodge", width = 0.6) +
      scale_fill_manual(values = c(ACCENT, AMBER)) +
      facet_wrap(~Metric, scales = "free", ncol = 3) +
      labs(x = NULL, y = "Value", fill = "Company") +
      theme_minimal(base_size = 12) +
      theme(strip.text = element_text(face = "bold"),
            axis.text.x = element_blank(),
            panel.grid.minor = element_blank())

    ggplotly(p, tooltip = "text")
  })

  output$table_compare <- renderDT({
    esg_data %>%
      filter(Year == 2023, Company %in% c(input$company_a, input$company_b)) %>%
      select(Company, Sector, Country, Environmental_Score, Social_Score,
             Governance_Score, ESG_Total, ESG_Rating,
             CO2_Emissions_MtCO2, Revenue_BillionUSD, CO2_per_Revenue) %>%
      rename(
        "E Score" = Environmental_Score,
        "S Score" = Social_Score,
        "G Score" = Governance_Score,
        "ESG Total" = ESG_Total,
        "Rating" = ESG_Rating,
        "CO2 (Mt)" = CO2_Emissions_MtCO2,
        "Revenue ($B)" = Revenue_BillionUSD,
        "CO2 Intensity" = CO2_per_Revenue
      ) %>%
      datatable(options = list(dom = "t", pageLength = 5),
                rownames = FALSE)
  })

  # ── FULL DATA TABLE ───────────────────────────────────
  output$full_table <- renderDT({
    filtered() %>%
      select(Company, Sector, Country, Year,
             Environmental_Score, Social_Score, Governance_Score,
             ESG_Total, ESG_Rating, CO2_Emissions_MtCO2,
             Revenue_BillionUSD, Employees, CO2_per_Revenue) %>%
      arrange(Year, desc(ESG_Total)) %>%
      datatable(
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      ) %>%
      formatStyle("ESG_Total",
                  background = styleColorBar(c(0, 100), ACCENT),
                  backgroundSize = "100% 80%",
                  backgroundRepeat = "no-repeat",
                  backgroundPosition = "center") %>%
      formatStyle("ESG_Rating",
                  color = styleEqual(
                    names(rating_colors), unname(rating_colors)
                  ),
                  fontWeight = "bold")
  })
}

# ── RUN ─────────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
