import os
import re


class OutputFile(object):
	FILENAME_RE = re.compile("^(.*_)(k(\d+)_c(\d+\.?\d*)_l(\d+)_n(\d+)_av(\d+\.?\d*)_t(\d+)_d(\d+))(.*)$")

	def __init__(
		self,
		filename,
		spec,
		prefix,
		postfix,
		k,
		hhc,
		l,
		n,
		alpha_v,
		timesteps,
		d_timesteps
	):
		self.filename = filename
		self.spec = spec

		self.prefix = prefix
		self.postfix = postfix

		self.k = k
		self.hhc = hhc
		self.l = l
		self.n = n
		self.alpha_v = alpha_v
		self.timesteps = timesteps
		self.d_timesteps = d_timesteps

	@classmethod
	def fromFilename(cls, filename):
		match = cls.FILENAME_RE.match(filename)

		if match is None:
			return None

		return cls(
			filename,
			match.group(2),
			match.group(1),
			match.group(10),
			int(match.group(3)),
			float(match.group(4)),
			int(match.group(5)),
			int(match.group(6)),
			float(match.group(7)),
			int(match.group(8)),
			int(match.group(9))
		)


def gen_listdir(dir, recursive=False):
	if recursive:
		for dirpath, _, filenames in os.walk(dir):
			for name in filenames:
				yield os.path.join(dirpath, name)
	else:
		for name in os.listdir(dir):
			if os.path.isfile(os.path.join(dir, name)):
				yield os.path.join(dir, name)

def parse(dir, recursive=False):
	for path in gen_listdir(dir, recursive=recursive):
		output_file = OutputFile.fromFilename(
			os.path.basename(path)
		)
		if output_file is not None:
			yield output_file

def write_reader(output_files, writer):
	l = list(output_files)

	writer.write("library(data.table)\n")

	writer.write("d = data.table(")

	for key in ("k", "hhc", "l", "n", "alpha_v", "timesteps", "d_timesteps"):
		writer.write(key + "=c(")
		writer.write(",".join(str(getattr(i, key)) for i in l))
		writer.write("),")

	writer.write("relativeMisfit=c(")
	writer.write(",".join('relativeMisfit("{}", prefix="{}", postfix="{}")'.format(i.spec, i.prefix, i.postfix) for i in l))
	writer.write(")")
	writer.write(")")

def main():
	pass

if __name__ == '__main__':
	main()
