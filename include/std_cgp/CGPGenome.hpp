#pragma once

#include <string>
#include <iostream>

#include "emp/base/vector.hpp"

namespace std_cgp {

struct OperatorGene {
  size_t op_id;
  emp::vector<size_t> op_sources;
};

class CGPGenome {
public:
protected:

  emp::vector<OperatorGene> genes;
  // size_t num_node_cols;
  // size_t num_node_rows;
  size_t num_inputs;

public:

  void Print(std::ostream& os=std::cout) const {
    for (size_t gene_i = 0; gene_i < genes.size(); ++gene_i) {
      const OperatorGene& gene = genes[gene_i];
      if (gene_i) os << " ";
      os << gene.op_id;
      os << "(";
      for (size_t input_i = 0; input_i < gene.op_sources.size(); ++input_i) {
        if (input_i) os << ",";
        os << gene.op_sources[input_i];
      }
    }
  }

};

}