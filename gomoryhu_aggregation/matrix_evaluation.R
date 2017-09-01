library(data.table)
d = fread(paste("matrix_", spec, ".out", sep=""))

# ...

d.melt = melt(d, c(), 1:ncol(d))
d.melt[,i := rowid(variable)]
d.melt[,j := .GRP,variable]

# ...

heatmap(as.matrix(d), Rowv = NA, Colv = NA, scale = "column", main = "Heatmap")

# ...

calculateHalfValue = function (d.melt) {
	d.melt.sorted = d.melt[order(value)]
	d.value.sum = d.melt[, sum(as.numeric(value))]
	half.sum = d.value.sum / 2
	running.sum = 0L
	for (i in 1:nrow(d.melt)) {
		running.sum = running.sum + d.melt.sorted[i,value]
		if (running.sum >= half.sum ) {
			half.value = d.melt.sorted[i,value]
			break
		}
	}

	return(half.value)
}

half.value = calculateHalfValue(d.melt)

# ...


calculateOptimalT = function (d.melt) {
	supercluster.size = d.melt[,.GRP,variable][,.N] / 2

	# d.melt[j <= supercluster.size & i <= supercluster.size] # Supercluster 1
	# d.melt[j > supercluster.size & i > supercluster.size]   # Supercluster 2
	# d.melt[j <= supercluster.size & i > supercluster.size]  # Inverse 1
	# d.melt[j > supercluster.size & i <= supercluster.size]  # Inverse 2

	intra.super = rbind(
		d.melt[j <= supercluster.size & i <= supercluster.size],
		d.melt[j > supercluster.size & i > supercluster.size]
	)
	inter.super = rbind(
		d.melt[j <= supercluster.size & i > supercluster.size],
		d.melt[j > supercluster.size & i <= supercluster.size]
	)

	# intra.super.ordered = intra.super[i != j][order(value)]
	# inter.super.ordered = inter.super[order(value)]

	# # All intra edges should have a higher value than inter edges

	# intra.super.min = intra.super[i != j,min(value)]
	# inter.super.max = inter.super[,max(value)]

	# intra.super.ordered[value <= inter.super.max]
	# inter.super.ordered[value >= intra.super.min]

	optimal.t = 0
	optimal.t.misfits = .Machine$integer.max

	for (t in inter.super[i != j,min(value)]:intra.super[,max(value)]) {
		misfits = intra.super[value <= t,.N] + inter.super[value >= t,.N]
		if (misfits < optimal.t.misfits) {
			optimal.t = t
			optimal.t.misfits = misfits
		}
	}

	return(c(optimal.t, optimal.t.misfits))
}

optimal = calculateOptimalT(d.melt)
optimal.t = optimal[1]
optimal.t.misfits = optimal[2]

# ...

# Ground truth colouring (0, 1)
gt.melt = copy(d.melt)
gt.melt[j <= supercluster.size & i <= supercluster.size, value := 1] # Supercluster 1
gt.melt[j > supercluster.size & i > supercluster.size, value := 1]   # Supercluster 2
gt.melt[j <= supercluster.size & i > supercluster.size, value := 0]  # Inverse 1
gt.melt[j > supercluster.size & i <= supercluster.size, value := 0]  # Inverse 2
gt = dcast(gt.melt, i ~ variable, value.var="value")

# ...

drawFiltered = function (d.melt, threshold, main = "Heatmap") {
	d2.melt = copy(d.melt)
	d2.melt[value <= threshold, value := 0][value > threshold, value := threshold + 1]

	d2 = dcast(d2.melt, i ~ variable, value.var="value")
	heatmap(as.matrix(d2), Rowv = NA, Colv = NA, scale = "column", main = main)
}

drawFiltered(d.melt, optimal.t)
dev.copy(pdf, paste("heatmap_Toptimal", optimal.t, "_", spec, ".pdf", sep=""))
dev.off()

drawFiltered(d.melt, half.value)
dev.copy(pdf, paste("heatmap_Thalfvalue", half.value, "_", spec, ".pdf", sep=""))
dev.off()

drawFiltered(d.melt, as.integer(d.melt[,mean(value)]))
dev.copy(pdf, paste("heatmap_Tmean", as.integer(d.melt[,mean(value)]), "_", spec, ".pdf", sep=""))
dev.off()

drawFiltered(d.melt, d.melt[,median(value)])
dev.copy(pdf, paste("heatmap_Tmedian", d.melt[,median(value)], "_", spec, ".pdf", sep=""))
dev.off()

# ...

threshold = 22880

m[m <= threshold] = 0
m[m > threshold] = 25000

# ...

drawDensity = function (d.melt, optimal.t, half.value) {
	d.summary = summary(d.melt[,value])
	plot(density(d.melt[value > d.summary["1st Qu."] & value < d.summary["3rd Qu."],value]), main="Aggregation Matrix Value Density from 1st to 3rd Quartile")
	abline(v=optimal.t, col="green")
	abline(v=d.summary["Mean"], col="red")
	abline(v=d.summary["Median"], col="black")
	abline(v=half.value, col="darkorchid")

	legend("topright",
			inset=0.05,
			c("mean", "median", "half value", "optimal"),
			col=c('red', 'black', 'darkorchid', "green"),
			lty=c(1, 1, 1, 1))
}

drawDensity(d.melt, optimal.t, half.value)
dev.copy(pdf, paste("density_", spec, ".pdf", sep=""), width=10)
dev.off()

processFile = function (spec, prefix="matrix_", postfix=".out") {
	d = fread(paste(prefix, spec, postfix, sep=""))

	d.melt = melt(d, c(), 1:ncol(d))
	d.melt[,i := rowid(variable)]
	d.melt[,j := .GRP,variable]

	heatmap(as.matrix(d), Rowv = NA, Colv = NA, scale = "column", main = "Heatmap")
	readline(prompt="Press [enter] to continue")

	optimal = calculateOptimalT(d.melt)
	optimal.t = optimal[1]
	optimal.t.misfits = optimal[2]

	print("Optimal t, misfits and relative misfits")
	print(optimal.t)
	print(optimal.t.misfits)
	print(optimal.t.misfits / d.melt[,.N])
	readline(prompt="Press [enter] to continue")

	half.value = calculateHalfValue(d.melt)

	drawDensity(d.melt, optimal.t, half.value)
	readline(prompt="Press [enter] to continue")

	drawFiltered(d.melt, optimal.t)
	readline(prompt="Press [enter] to continue")
}

