#pragma once

#include "emp/base/vector.hpp"

namespace std_cgp {

class CGPGenome {
public:
protected:

  emp::vector<size_t> sites;
  size_t num_node_cols;
  size_t num_node_rows;

public:

};

class CGPNode {
  size_t operator_id;
  emp::vector<size_t> input_connections;
  emp::vector<size_t> output_connections;
};

class CGPHardware {
public:
  using genome_t = CGPGenome;
protected:
  emp::vector<CGPNode> nodes; // CGP Nodes arranged in a grid
  size_t num_node_cols;
  size_t num_node_rows;

public:

  void LoadGenome







};

}