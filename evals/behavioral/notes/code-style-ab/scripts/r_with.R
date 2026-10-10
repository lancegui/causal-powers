library(dplyr)
library(readr)
library(lubridate)
library(fixest)
library(ggplot2)
library(ggthemes)

df <- read_csv("Data/shipments.csv")
pharm_link <- read_csv("Data/pharm_link.csv")
pharmacies <- read_csv("Data/pharmacies.csv")
bup_ndc <- read_csv("Data/ndc.csv")

nrow(df)
summary(df)
range(df$TRANSACTION_DATE)

################ keep moud shipments ################

moud_ndc <- bup_ndc %>% filter(MOUD) %>% distinct(NDC_NO) %>% pull()
length(moud_ndc)
sum(unique(df$NDC_NO) %in% bup_ndc$NDC_NO) / n_distinct(df$NDC_NO)

df <- df %>% filter(NDC_NO %in% moud_ndc)
nrow(df)
sum(df$CALC_BASE_WT_IN_GM)

################ map shipments to pharmacy ################

# a pharmacy can hold several dea numbers, each dea number maps to one pharmacy
sum(duplicated(pharm_link$BUYER_DEA_NO))
n_distinct(pharm_link$pharmacy_id)

n0 <- nrow(df)
df <- df %>% left_join(pharm_link %>% select(BUYER_DEA_NO, pharmacy_id), by = "BUYER_DEA_NO")
nrow(df)
stopifnot(nrow(df) == n0)
sum(is.na(df$pharmacy_id))
n_distinct(df$pharmacy_id)

################ pharmacy by month grams ################

pharm_month <- df %>%
  mutate(month = floor_date(TRANSACTION_DATE, "month")) %>%
  group_by(pharmacy_id, month) %>%
  summarise(grams = sum(CALC_BASE_WT_IN_GM), .groups = "drop")

nrow(pharm_month)
sum(pharm_month$grams) / sum(df$CALC_BASE_WT_IN_GM)

# fill months with no shipment with 0, from each pharmacy's first shipment month through 2019-12
last_month <- as.Date("2019-12-01")
pharm_month <- pharm_month %>%
  group_by(pharmacy_id) %>%
  tidyr::complete(month = seq(min(month), last_month, by = "month"), fill = list(grams = 0)) %>%
  ungroup()

nrow(pharm_month)
sum(pharm_month$grams) / sum(df$CALC_BASE_WT_IN_GM)
pharm_month %>%
  group_by(pharmacy_id) %>%
  summarise(first_month = min(month), last_month = max(month), n_month = n(), .groups = "drop") %>%
  summary()

saveRDS(pharm_month, "Temp_Analysis_Data/moud_grams_by_pharmacy_month.RDS")

################ stock-out share by pharmacy ################

pharm_month <- readRDS("Temp_Analysis_Data/moud_grams_by_pharmacy_month.RDS")

# a stock-out month is a month with zero grams shipped
stock_out <- pharm_month %>%
  mutate(stock_out = ifelse(grams == 0, 1, 0)) %>%
  group_by(pharmacy_id) %>%
  summarise(n_month = n(), n_stock_out = sum(stock_out), stock_out_share = mean(stock_out), .groups = "drop")

nrow(stock_out)
summary(stock_out$stock_out_share)

n0 <- nrow(stock_out)
stock_out <- stock_out %>% left_join(pharmacies %>% select(pharmacy_id, zip, CHAIN), by = "pharmacy_id")
nrow(stock_out)
stopifnot(nrow(stock_out) == n0)
sum(is.na(stock_out$CHAIN))
table(stock_out$CHAIN)

saveRDS(stock_out, "Temp_Analysis_Data/stock_out_by_pharmacy.RDS")

################ stock-out share by chain ################

stock_out <- readRDS("Temp_Analysis_Data/stock_out_by_pharmacy.RDS")

stock_out %>%
  group_by(CHAIN) %>%
  summarise(n_pharmacy = n(), mean_share = mean(stock_out_share), sd_share = sd(stock_out_share), .groups = "drop")

model <- feols(stock_out_share ~ CHAIN | zip, data = stock_out, cluster = "zip")
summary(model)
etable(model)

stock_out %>%
  mutate(chain = ifelse(CHAIN == 1, "Chain", "Independent")) %>%
  ggplot(aes(x = stock_out_share, fill = chain, linetype = chain)) +
  geom_density(alpha = 0.5) +
  labs(x = "Share of months with no MOUD shipment", y = NULL) +
  theme_hc() +
  scale_fill_ptol() +
  theme(legend.title = element_blank(), text = element_text(size = 16.5))
ggsave("Plots/stock_out_rate_by_chain.png", width = 2000, height = 1500, units = "px")
