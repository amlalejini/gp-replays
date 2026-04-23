#pragma once

#include <string>
#include <utility>
#include <algorithm>
#include <functional>
#include <iostream>
#include <sys/stat.h>

#include "emp/Evolve/World.hpp"

#include "CGPConfig.hpp"


namespace std_cgp {
namespace world_defs {
  using ORGANISM_T = int;
}

class CGPWorld : public emp::World<world_defs::ORGANISM_T> {
public:
  using base_t = emp::World<world_defs::ORGANISM_T>;
  using config_t = CGPConfig;
protected:
  const config_t& config;

  std::string output_dir; // Directory to dump output

  bool world_configured = false;

  // -- Internal member functions --
  void Setup();

public:
  CGPWorld(
    const config_t& in_config
  ) :
    base_t("CGPWorld", false),
    config(in_config)
  {
    NewRandom(config.SEED());
    Setup();
  }



};

void CGPWorld::Setup() {
  std::cout << "-- Setting up CGPWorld --" << std::endl;
  world_configured = false;

  // Reset the world
  Reset();

  // Configure output directory path, create directory
  output_dir = config.OUTPUT_DIR();
  mkdir(output_dir.c_str(), ACCESSPERMS);
  if(output_dir.back() != '/') {
      output_dir += '/';
  }

  // Setup the population structure with synchronous generations
  SetPopStruct_Mixed(true);

  world_configured = true;
}


}