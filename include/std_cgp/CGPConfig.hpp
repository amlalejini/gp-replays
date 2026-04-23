#pragma once

#include "emp/config/config.hpp"

namespace std_cgp {

EMP_BUILD_CONFIG(CGPConfig,
  GROUP(WORLD, "General world configuration"),
  VALUE(SEED, int, 0, "Random number seed"),

  GROUP(OUTPUT, "Output settings"),
  VALUE(OUTPUT_DIR, std::string, "./output/", "What directory are we dumping all this data")
);

}