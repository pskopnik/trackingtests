library(data.table)

relativeMisfit = function (spec, prefix="matrix_", postfix=".out") {
	d = fread(paste(prefix, spec, postfix, sep=""))

	d.melt = melt(d, c(), 1:ncol(d))
	d.melt[,i := rowid(variable)]
	d.melt[,j := .GRP,variable]

	optimal = calculateOptimalT(d.melt)
	optimal.t.misfits = optimal[2]
	return(optimal.t.misfits / d.melt[,.N])
}

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

	drawDensity(d.melt, optimal.t)
	readline(prompt="Press [enter] to continue")

	drawFiltered(d.melt, optimal.t)
	readline(prompt="Press [enter] to continue")
}

drawFiltered = function (d.melt, threshold, main = "Heatmap") {
	d2.melt = copy(d.melt)
	d2.melt[value <= threshold, value := 0][value > threshold, value := threshold + 1]

	d2 = dcast(d2.melt, i ~ variable, value.var="value")
	heatmap(as.matrix(d2), Rowv = NA, Colv = NA, scale = "column", main = main)
}


drawDensity = function (d.melt, optimal.t) {
	d.summary = summary(d.melt[,value])
	# plot(density(d.melt[value > d.summary["1st Qu."] & value < d.summary["3rd Qu."],value]), main="Aggregation Matrix Value Density from 1st to 3rd Quartile")
	plot(density(d.melt[,value]), main="Aggregation Matrix Value Density")
	abline(v=optimal.t, col="green")
	abline(v=d.summary["Mean"], col="red")
	abline(v=d.summary["Median"], col="black")
	#abline(v=half.value, col="darkorchid")

	legend("topright",
			inset=0.05,
			c("mean", "median", "optimal"),
			col=c('red', 'black', "green"),
			lty=c(1, 1, 1, 1))
}

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

drawRelativeMisfitCorrelatedToAlpha = function (d) {
	d.filtered = d[k == 240 & l == 80 & timesteps == 100 & d_timesteps == 3000]

	hhc.values = d.filtered[order(hhc),hhc,hhc][,hhc]

	colors = rev(heat.colors(length(hhc.values) + 1)[1:length(hhc.values)])
	# colors = rev(topo.colors(length(hhc.values)))

	plot(
	c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="alpha_v",
	main="Relative Misfit",
	sub="k=240, hhc=?, l=80, n=10000, timesteps=100, d_timesteps=3000"
	)

	for (i in 1:length(hhc.values)) {
		points(relativeMisfit ~ alpha_v, data=d.filtered[hhc == hhc.values[i]][order(alpha_v)], t="o", col=colors[i])
	}

	legend("bottomleft",
			inset=0.05,
			title="hhc",
			legend=hhc.values,
			col=colors,
			pch=rep(1, length(hhc.values)))

	dev.copy(pdf, "relative_misfit_by_alpha_v.pdf", width=10)
	dev.off()
}

drawRelativeMisfitCorrelatedToAlphaTimesteps = function (d) {
	d.filtered = d[k == 240 & hhc == 0.01 & l == 80 & d_timesteps == 300]

	timesteps.values = d.filtered[order(timesteps),timesteps,timesteps][,timesteps]

	colors = rev(heat.colors(length(timesteps.values) + 1)[1:length(timesteps.values)])
	# colors = rev(topo.colors(length(timesteps.values)))

	plot(
	c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="alpha_v",
	main="Relative Misfit",
	sub="k=240, hhc=0.01, l=80, n=10000, timesteps=?, d_timesteps=3000"
	)

	for (i in 1:length(timesteps.values)) {
		points(relativeMisfit ~ alpha_v, data=d.filtered[timesteps == timesteps.values[i]][order(alpha_v)], t="o", col=colors[i])
	}

	legend("bottomleft",
			inset=0.05,
			title="timesteps",
			legend=timesteps.values,
			col=colors,
			pch=rep(1, length(timesteps.values)))

	dev.copy(pdf, "relative_misfit_by_alpha_v_timesteps.pdf", width=10)
	dev.off()
}

drawRelativeMisfitCorrelatedToAlphaDTimesteps = function (d) {
	d.filtered = d[k == 240 & hhc == 0.01 & l == 80 & timesteps == 100]

	d_timesteps.values = d.filtered[order(d_timesteps),d_timesteps,d_timesteps][,d_timesteps]

	colors = rev(heat.colors(length(d_timesteps.values) + 1)[1:length(d_timesteps.values)])
	# colors = rev(topo.colors(length(d_timesteps.values)))

	plot(
	c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="alpha_v",
	main="Relative Misfit",
	sub="k=240, hhc=0.01, l=80, n=10000, timesteps=100, d_timesteps=?"
	)

	for (i in 1:length(d_timesteps.values)) {
		points(relativeMisfit ~ alpha_v, data=d.filtered[d_timesteps == d_timesteps.values[i]][order(alpha_v)], t="o", col=colors[i])
	}

	legend("bottomleft",
			inset=0.05,
			title="d_timesteps",
			legend=d_timesteps.values,
			col=colors,
			pch=rep(1, length(d_timesteps.values)))

	dev.copy(pdf, "relative_misfit_by_alpha_v_d_timesteps.pdf", width=10)
	dev.off()
}


drawRelativeMisfitCorrelatedToHHC = function (d) {
	d.filtered = d[k == 240 & l == 80 & timesteps == 100 & d_timesteps == 3000]

	alpha_v.values = d.filtered[order(alpha_v),alpha_v,alpha_v][,alpha_v]

	colors = rev(heat.colors(length(alpha_v.values) + 1)[1:length(alpha_v.values)])
	# colors = rev(topo.colors(length(alpha_v.values)))

	plot(
	c(d.filtered[,min(hhc)], d.filtered[,max(hhc)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="hhc",
	main="Relative Misfit",
	sub="k=240, alpha_v=?, l=80, n=10000, timesteps=100, d_timesteps=3000"
	)

	for (i in 1:length(alpha_v.values)) {
		points(relativeMisfit ~ hhc, data=d.filtered[alpha_v == alpha_v.values[i]][order(hhc)], t="o", col=colors[i])
	}

	legend("bottomright",
			inset=0.05,
			title="alpha_v",
			legend=alpha_v.values,
			col=colors,
			pch=rep(1, length(alpha_v.values)))

	dev.copy(pdf, "relative_misfit_by_hhc.pdf", width=10)
	dev.off()
}
