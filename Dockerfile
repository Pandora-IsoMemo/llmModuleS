FROM inwt/r-shiny:4.3.2

RUN echo "options(repos = c(getOption('repos'), PANDORA = 'https://Pandora-IsoMemo.github.io/drat/'))" >> /usr/local/lib/R/etc/Rprofile.site

ADD . .

RUN installPackage

# Expose ports
EXPOSE 3838

CMD ["Rscript", "-e", "library(shiny); llmModule::startApplication(3838, host = '0.0.0.0')"]
