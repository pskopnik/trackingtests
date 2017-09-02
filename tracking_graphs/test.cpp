#include "test.h"

#include <sstream>
#include <vector>
#include <algorithm>

#include <NetworKit/generators/DynamicCommunitiesGenerator.h>
#include <NetworKit/structures/Partition.h>
#include <NetworKit/correspondences/Tracking.h>


void run(unsigned int k, double hhc, unsigned int l, unsigned int n, double alpha_v,
	unsigned int timesteps, unsigned int d_timesteps
) {
	std::vector<std::vector<NetworKit::index>> parts;
	NetworKit::AffinitiesGenerator aGen;

	auto m = aGen.halfHalf(k, hhc, parts);

	NetworKit::DynamicCommunitiesGenerator::Parameters parameters{m, l, n, alpha_v};

	NetworKit::DynamicCommunitiesGenerator gen(parameters);
	NetworKit::GeneratorState state(gen);

	NetworKit::StepByStep<
		NetworKit::DCGTimestepData,
		NetworKit::DCGHierarchicalTree<
			NetworKit::CheapestMutual
		>,
		NetworKit::OwnershipDotOutput<NetworKit::DCGTimestepData>
	> tCheapestMutual(
		NetworKit::DCGTimestepData(parts),
		NetworKit::DCGHierarchicalTree<
			NetworKit::CheapestMutual
		>(gen, parts)
	);

	NetworKit::StepByStep<
		NetworKit::DCGTimestepData,
		NetworKit::DCGHierarchicalTree<
			NetworKit::RecursiveMutual
		>,
		NetworKit::OwnershipDotOutput<NetworKit::DCGTimestepData>
	> tRecursiveMutual(
		NetworKit::DCGTimestepData(parts),
		NetworKit::DCGHierarchicalTree<
			NetworKit::RecursiveMutual
		>(gen, parts)
	);

	NetworKit::StepByStep<
		NetworKit::DCGTimestepData,
		NetworKit::DCGHierarchicalTree<
			NetworKit::TopDown<
				NetworKit::IndividualOptimumWeakenedZero
			>
		>,
		NetworKit::OwnershipDotOutput<NetworKit::DCGTimestepData>
	> tTopDownIndividualOptimumWeakenedZero(
		NetworKit::DCGTimestepData(parts),
		NetworKit::DCGHierarchicalTree<
			NetworKit::TopDown<NetworKit::IndividualOptimumWeakenedZero>
		>(gen, parts)
	);

	NetworKit::StepByStep<
		NetworKit::DCGTimestepData,
		NetworKit::DCGLeafExpansion,
		NetworKit::OwnershipDotOutput<NetworKit::DCGTimestepData>
	> tLeafExpansion(
		NetworKit::DCGTimestepData(parts),
		NetworKit::DCGLeafExpansion(gen, parts)
	);


	for (unsigned int i = 0; i < timesteps * d_timesteps; ++i) {
		NetworKit::Partition p = gen.next();
		if (i % d_timesteps == 0) {
			tCheapestMutual.add(p);
			tRecursiveMutual.add(p);
			tTopDownIndividualOptimumWeakenedZero.add(p);
			tLeafExpansion.add(p);
		}
	}

	tCheapestMutual.getOutputer().aggregateToFile("graph.CheapestMutual.dot");

	tRecursiveMutual.getOutputer().aggregateToFile("graph.RecursiveMutual.dot");

	tTopDownIndividualOptimumWeakenedZero.getOutputer().aggregateToFile("graph.TopDownIndividualOptimumWeakenedZero.dot");

	tLeafExpansion.getOutputer().aggregateToFile("graph.LeafExpansion.dot");
}

int main(int argc, char const *argv[]) {
	unsigned int k, l, n, timesteps, d_timesteps;
	double hhc, alpha_v;

	if (argc != 8) {
		std::cerr << "Invalid number of arguments passed (expected 7): " << argc - 1 << std::endl;
		return 1;
	}

	std::istringstream ss;

	ss.str(std::string(argv[1]));
	ss.clear();
	if (!(ss >> k)) {
		std::cerr << "Invalid value for k (expected int): " << argv[1] << std::endl;
		return 1;
	}

	ss.str(std::string(argv[2]));
	ss.clear();
	if (!(ss >> hhc)) {
		std::cerr << "Invalid value for hhc (expected double): " << argv[2] << std::endl;
		return 1;
	}

	ss.str(std::string(argv[3]));
	ss.clear();
	if (!(ss >> l)) {
		std::cerr << "Invalid value for l (expected int): " << argv[3] << std::endl;
		return 1;
	}

	ss.str(std::string(argv[4]));
	ss.clear();
	if (!(ss >> n)) {
		std::cerr << "Invalid value for n (expected int): " << argv[4] << std::endl;
		return 1;
	}

	ss.str(std::string(argv[5]));
	ss.clear();
	if (!(ss >> alpha_v)) {
		std::cerr << "Invalid value for alpha_v (expected double): " << argv[5] << std::endl;
		return 1;
	}

	ss.str(std::string(argv[6]));
	ss.clear();
	if (!(ss >> timesteps)) {
		std::cerr << "Invalid value for timesteps (expected int): " << argv[6] << std::endl;
		return 1;
	}

	ss.str(std::string(argv[7]));
	ss.clear();
	if (!(ss >> d_timesteps)) {
		std::cerr << "Invalid value for d_timesteps (expected int): " << argv[7] << std::endl;
		return 1;
	}

	run(k, hhc, l, n, alpha_v, timesteps, d_timesteps);

	return 0;
}
