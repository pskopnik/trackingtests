import argparse
import os
import re
import shutil


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

def write_data_table(output_files, writer, data_table_import=True):
	l = list(output_files)

	if data_table_import:
		writer.write("library(data.table)\n")

	writer.write("d = data.table(")

	for key in ("k", "hhc", "l", "n", "alpha_v", "timesteps", "d_timesteps"):
		writer.write(key + "=c(")
		writer.write(",".join(str(getattr(i, key)) for i in l))
		writer.write("),")

	writer.write("relativeMisfit=c(")
	writer.write(
		",".join(
			'relativeMisfit("{}", prefix="{}", postfix="{}")'
				.format(i.spec, i.prefix, i.postfix) for i in l
		)
	)
	writer.write(")")
	writer.write(")")
	writer.write("\n")

def main(dir, output, preamble=None, data_file=None):
	with open(output, "w") as f:

		if preamble is not None:
			with open(preamble) as p:
				shutil.copyfileobj(p, f)

			f.write("\n")

		write_data_table(parse(dir), f)

		if data_file is not None:
			f.write("\n")

			f.write('fwrite(d, "{}", sep=" ")\n'.format(data_file))

parser = argparse.ArgumentParser(description='Generates a R evaluation script.')
parser.add_argument('dir', help='The input directory')
parser.add_argument('output', nargs='?', default="evaluate.tmp.R",
	help='The path the script is written to (default: evaluate.tmp.R)')
parser.add_argument('-p', '--preamble', nargs='?',
	help='Path to a preamble file, inserted before the data.table')
parser.add_argument('-d', '--data-file', nargs='?', dest="data_file",
	help='Path to a data file the data.table is written to')


if __name__ == '__main__':
	args = parser.parse_args()

	main(args.dir, args.output, preamble=args.preamble, data_file=args.data_file)
