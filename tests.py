from bjec import job, build, P, Factory, Join
from bjec.params import Function
from bjec.build import GitRepo, Make
from bjec.runner import SubprocessRunner, ProcessArgs, Stdout
from bjec.processor import Threading
from bjec.generator import Product, RepeatG, List
from bjec.collector import Concatenate, CSV, Demux
from bjec.config import config

from os.path import join
import os


repo_url = config.User["repo_url"]
no_of_runs = config.User.get("no_of_runs", 100)


@build()
def build_gomoryhu_aggregation(b):
	s = b.source(GitRepo(repo_url))

	m = b.builder(Make(join(s.local_path(), "gomoryhu_aggregation"), creates="test"))

	b.artefact(executable=m.result)

@job(depends=build_gomoryhu_aggregation)
def gomoryhu_aggregation(j):
	j.generator(
		Product(
			k=[240],
			hhc=[0.01],
			k_over_l=[3],
			n=[10000],
			alpha_v=[0.7, 0.8, 0.85, 0.9, 0.93, 0.95, 0.96, 0.97, 0.98, 0.99, 0.99],
			timesteps=[100],
			d_timesteps=[300]
		)
	)

	j.processor(Threading(
		config.User.get("cpu_count", os.cpu_count())
	))

	j.runner(SubprocessRunner.factory(
		j.dependencies[build_gomoryhu_aggregation].artefacts["executable"],
		input=ProcessArgs(
			P("k"),
			P("hhc"),
			Function(lambda p: p["k"] // p["k_over_l"]),
			P("n"),
			P("alpha_v"),
			P("timesteps"),
			P("d_timesteps")
		),
		output=Stdout(),
	))

	coll = j.collector(Demux(
		["k", "hhc", "k_over_l", "n", "alpha_v", "timesteps", "d_timesteps"],
		Factory(
			Concatenate,
			file_path=Join(
				"gomoryhu_aggregation",
				"_k", P("k"),
				"_c", P("hhc"),
				"_l", Function(lambda p: p["k"] // p["k_over_l"]),
				"_n", P("n"),
				"_av", P("alpha_v"),
				"_t", P("timesteps"),
				"_d", P("d_timesteps"),
				".out"
			),
		)
	))

	j.artefact(result=coll.aggregate)

	j.after(lambda j: print("Wrote results to", list(map(lambda f: f.name, j.artefacts["result"]))))
	j.after(lambda j: list(map(lambda f: f.close(), j.artefacts["result"])))
