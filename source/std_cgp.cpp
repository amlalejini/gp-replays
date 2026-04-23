// This is the main function for the NATIVE version of this project.

#include <iostream>
#include <limits>

#include "emp/base/vector.hpp"
#include "emp/config/command_line.hpp"
#include "emp/config/ArgManager.hpp"

#include "../include/std_cgp/CGPConfig.hpp"
#include "../include/std_cgp/CGPWorld.hpp"


int main(int argc, char* argv[])
{
  std_cgp::CGPConfig config;
  config.Read("std_cgp.cfg", false);
  auto args = emp::cl::ArgManager(argc, argv);
  if (args.ProcessConfigOptions(config, std::cout, "std_cgp.cfg", "std_cgp-macros.h") == false) exit(0);
  if (args.TestUnknown() == false) exit(0);  // If there are leftover args, throw an error.

  std::cout << "==============================" << std::endl;
  std::cout << "|    How am I configured?    |" << std::endl;
  std::cout << "==============================" << std::endl;
  config.Write(std::cout);
  std::cout << "==============================\n"
            << std::endl;

  std_cgp::CGPWorld world(config);
  // world.Run();

}