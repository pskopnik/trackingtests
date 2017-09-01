	d.filtered = d[k == 240 & hhc == 0.01 & timesteps == 100 & d_timesteps == 600]

	l.values = d.filtered[order(l),l,l][,l]

	colors = rev(heat.colors(length(l.values) + 1)[1:length(l.values)])
	# colors = rev(topo.colors(length(l.values)))

	plot(
	c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="alpha_v",
	main="Relative Misfit",
	sub="k=240, hhc=0.01, l=?, n=10000, timesteps=100, d_timesteps=600"
	)

	for (i in 1:length(l.values)) {
		points(relativeMisfit ~ alpha_v, data=d.filtered[l == l.values[i]][order(alpha_v)], t="o", col=colors[i], pch=3)
	}

	legend("bottomleft",
			inset=0.05,
			title="l",
			legend=l.values,
			col=colors,
			pch=rep(3, length(l.values)))

	# dev.copy(pdf, "relative_misfit_by_l_k60.pdf", width=10)
	# dev.off()



	d.filtered = d[k == 120 & hhc == 0.01 & timesteps == 100 & d_timesteps == 600]

	l.values = d.filtered[order(l),l,l][,l]

	colors = rev(heat.colors(length(l.values) + 1)[1:length(l.values)])
	# colors = rev(topo.colors(length(l.values)))

	plot(
	c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="alpha_v",
	main="Relative Misfit",
	sub="k=120, hhc=0.01, l=?, n=10000, timesteps=100, d_timesteps=600"
	)

	for (i in 1:length(l.values)) {
		points(relativeMisfit ~ alpha_v, data=d.filtered[l == l.values[i]][order(alpha_v)], t="o", col=colors[i], pch=3)
	}

	legend("bottomleft",
			inset=0.05,
			title="l",
			legend=l.values,
			col=colors,
			pch=rep(3, length(l.values)))

	# dev.copy(pdf, "relative_misfit_by_l_k60.pdf", width=10)
	# dev.off()



	d.filtered = d[k == 60 & hhc == 0.01 & timesteps == 100 & d_timesteps == 600]

	l.values = d.filtered[order(l),l,l][,l]

	colors = rev(heat.colors(length(l.values) + 1)[1:length(l.values)])
	# colors = rev(topo.colors(length(l.values)))

	plot(
	c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
	c(0, d.filtered[,max(relativeMisfit)]),
	t="n",
	ylab="Relative Misfit",
	xlab="alpha_v",
	main="Relative Misfit",
	sub="k=60, hhc=0.01, l=?, n=10000, timesteps=100, d_timesteps=600"
	)

	for (i in 1:length(l.values)) {
		points(relativeMisfit ~ alpha_v, data=d.filtered[l == l.values[i]][order(alpha_v)], t="o", col=colors[i], pch=3)
	}

	legend("bottomleft",
			inset=0.05,
			title="l",
			legend=l.values,
			col=colors,
			pch=rep(3, length(l.values)))

	# dev.copy(pdf, "relative_misfit_by_l_k60.pdf", width=10)
	# dev.off()


# Evaluate for fixed k/l

# d.filtered = d[hhc == 0.01 & timesteps == 100 & d_timesteps == 600]

# k.values = d.filtered[order(k),k,k][,k]

# colors = rev(heat.colors(length(k.values) + 1)[1:length(k.values)])
# # colors = rev(topo.colors(length(k.values)))

# plot(
# c(d.filtered[,min(alpha_v)], d.filtered[,max(alpha_v)]),
# c(0, d.filtered[,max(relativeMisfit)]),
# t="n",
# ylab="Relative Misfit",
# xlab="alpha_v",
# main="Relative Misfit",
# sub="hhc=0.01, l=k/3 n=10000, timesteps=100, d_timesteps=600"
# )

# for (i in 1:length(k.values)) {
# 	points(relativeMisfit ~ alpha_v, data=d.filtered[k == k.values[i] & l == as.integer(k/3)][order(alpha_v)], t="o", col=colors[i])
# }

# legend("bottomleft",
# 		inset=0.05,
# 		title="k",
# 		legend=k.values,
# 		col=colors,
# 		pch=rep(1, length(k.values)))

# # dev.copy(pdf, "relative_misfit_by_.pdf", width=10)
# # dev.off()

