#!/usr/bin/env Rscript
# segment copy number data and generate plot

suppressPackageStartupMessages(library("optparse"));
suppressPackageStartupMessages(library("CGHcall"));

options(warn = -1, error = quote({ traceback(); q('no', status = 1) }))

optList <- list(
                make_option("--centromereFile", default = NULL, type = "character", action = "store", help ="centromere file"),
                make_option("--prefix", default = NULL, type = "character", action = "store", help ="Output prefix (required)"))

parser <- OptionParser(usage = "%prog [options] segment.Rdata", option_list = optList);
arguments <- parse_args(parser, positional_arguments = T);
opt <- arguments$options;

if (length(arguments$args) != 1) {
    cat("Need segmented copy number R data file\n\n");
    print_help(parser);
    stop();
} else if (is.null(opt$prefix)) {
    cat("Need output prefix\n\n");
    print_help(parser);
    stop();
} else {
    segFile <- arguments$args[1];
}

load(segFile)

calls <- CGHcall(segmented, nclass=3, minlsforfit = 0.3)
excalls <- ExpandCGHcall(calls, segmented)

Data <- cbind(fData(excalls), copynumber(excalls), segmented(excalls), calls(excalls))
colnames(Data)[5:6] <- c("log2_ratio_seg", "Calls")

write.table(Data, file = paste(opt$prefix, ".cgh_call.txt", sep=""), col.names=NA, quote=F, sep="\t")


colours <- Data$Calls
colours[which(colours==0)] <- "black"
colours[which(colours== -1)] <- "darkred"
colours[which(colours==1)] <- "darkgreen"
colours[which(colours==2)] <- "green"
colours[which(colours==-2)] <- "red"

ylim <- c(min(as.numeric(Data[,4])), max(as.numeric(Data[,4])))
ylim[2] <- ylim[2]+0.5
pdf(paste(opt$prefix,".seg_call_plot.pdf", sep=""), height=5, width=18)
plot(as.numeric(Data[,4]), pch=20, xlab='Position', ylab="Copy number", xaxt='n', col = colours, ylim=ylim)
abline(v=cumsum(rle(Data$Chr)$lengths), col="red", lty=3)

if (!is.null(opt$centromereFile)) {
    cen <- read.table(opt$centromereFile, sep = '\t')
    for (j in unique(cen[,1])) {
        pos <- cen[which(cen[,1]==j)[1],3]
        index <- which(Data$Chromosome==j & Data$Start > pos)[1]
        if (!is.na(index)) {
            abline(v=index, col="darkgrey", lty=3)
        }
        text(cumsum(rle(Data$Chromosome)$lengths)-((rle(Data$Chromosome)$lengths)/2), ylim[2]-0.25)
    }
}
dev.off()
