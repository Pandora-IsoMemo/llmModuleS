FROM inwt/r-shiny:4.3.2

RUN echo "options(repos = c(CRAN = 'https://cloud.r-project.org', PANDORA = 'https://Pandora-IsoMemo.github.io/drat/'))" >> /usr/local/lib/R/etc/Rprofile.site

ADD . .

RUN apt-get update && apt-get install -y --no-install-recommends \
    libuv1-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

RUN installPackage

# Expose ports
EXPOSE 3838

CMD ["Rscript", "-e", "library(shiny); llmModuleS::startApplication(3838, host = '0.0.0.0')"]
