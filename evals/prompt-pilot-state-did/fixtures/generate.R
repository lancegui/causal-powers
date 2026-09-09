#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(fixest); library(jsonlite); library(digest)})
args <- commandArgs(trailingOnly=TRUE)
out <- if (length(args)) args[1] else "."
dir.create(out, recursive=TRUE, showWarnings=FALSE)
set.seed(20260909)

st <- data.frame(
  state_id=sprintf("S%02d", 1:40),
  region=rep(c("North","South","East","West"), each=10),
  treated=rep(rep(c(1L,0L), each=5), 4),
  population=round(runif(40, .7, 8.5)*1e6)
)
mo <- seq(as.Date("2018-01-01"), as.Date("2022-12-01"), by="month")
d <- merge(st, data.frame(month=mo))
d <- d[order(d$state_id,d$month),]
d$adoption_date <- as.Date(ifelse(d$treated==1L,"2021-01-01",NA), origin="1970-01-01")
d$post <- as.integer(d$month>=as.Date("2021-01-01"))
d$policy <- d$treated*d$post
a <- setNames(rnorm(40,55,6),st$state_id)
mi <- match(d$month,mo)
re <- c(North=-4.5,South=-2,East=-6,West=-3)
d$opioid_rate <- a[d$state_id]+2.2*sin(2*pi*mi/12)+.045*mi+
  re[d$region]*d$policy+as.vector(arima.sim(list(ar=.35),n=nrow(d),sd=1.7))
d$source_vintage <- "v1_2023-01-15"
d <- d[,c("state_id","region","month","population","treated","adoption_date",
          "opioid_rate","source_vintage")]
write.csv(d,file.path(out,"panel_v1.csv"),row.names=FALSE,na="")

u <- d[d$month>=as.Date("2021-07-01"),]
set.seed(20260910)
u$opioid_rate <- u$opioid_rate+rnorm(nrow(u),.35,.22)
u$source_vintage <- "update_2023-04-20"
u$revision_ts <- "2023-04-20T09:00:00Z"
u$treated[u$treated==0L] <- NA_integer_
dup <- u[u$state_id=="S03" & u$month==as.Date("2022-03-01"),]
dup$opioid_rate <- dup$opioid_rate-9
dup$revision_ts <- "2023-04-19T16:00:00Z"
u <- rbind(u,dup)
u <- u[sample(seq_len(nrow(u))),]
write.csv(u,file.path(out,"panel_update.csv"),row.names=FALSE,na="")

estimate <- function(x) {
  x$month <- as.Date(x$month)
  x$time_num <- as.integer(format(x$month,"%Y"))*12+as.integer(format(x$month,"%m"))
  x$post <- as.integer(x$month>=as.Date("2021-01-01"))
  x$policy <- x$treated*x$post
  m <- feols(opioid_rate~policy|state_id+month,x,cluster=~state_id)
  h <- feols(opioid_rate~0+policy:region|state_id+month,x,cluster=~state_id)
  z <- feols(opioid_rate~policy|state_id[time_num]+month,x,cluster=~state_id)
  list(primary=list(coef=unname(coef(m)["policy"]),se=unname(se(m)["policy"])),
       region=as.list(setNames(unname(coef(h)),names(coef(h)))),
       alternative=list(coef=unname(coef(z)["policy"]),se=unname(se(z)["policy"])))
}

v1 <- read.csv(file.path(out,"panel_v1.csv"),stringsAsFactors=FALSE)
up <- read.csv(file.path(out,"panel_update.csv"),stringsAsFactors=FALSE)
up <- up[order(up$state_id,up$month,up$revision_ts,decreasing=TRUE),]
up <- up[!duplicated(up[c("state_id","month")]),]
up$treated[is.na(up$treated)] <- 0L
k1 <- paste(v1$state_id,v1$month); ku <- paste(up$state_id,up$month)
v2 <- rbind(v1[!k1%in%ku,names(v1)],up[,names(v1)])
v2 <- v2[order(v2$state_id,v2$month),]
oracle <- list(seed=20260909,
 rows=list(v1=nrow(v1),update_raw=nrow(read.csv(file.path(out,"panel_update.csv"))),
           update_dedup=nrow(up),v2=nrow(v2)),
 hashes=list(v1=digest(file.path(out,"panel_v1.csv"),"sha256",file=TRUE),
             update=digest(file.path(out,"panel_update.csv"),"sha256",file=TRUE)),
 v1=estimate(v1),v2=estimate(v2))
write_json(oracle,file.path(out,"oracle.json"),pretty=TRUE,auto_unbox=TRUE,digits=16)
