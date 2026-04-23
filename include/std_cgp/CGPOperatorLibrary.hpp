#pragma once

#include <string>
#include <map>
#include <functional>

#include "emp/base/vector.hpp"
#include "emp/datastructs/map_utils.hpp"

namespace std_cgp {

template<typename HARDWARE_T>
struct OperatorDef {
  using op_fun_t = std::function<void(HARDWARE_T&, )>;
  std::string name;     ///< Name of this operator.
  std::string desc;     ///< Description of the operator.
  size_t num_inputs;
  // inst_fun_t fun_call;  ///< Function to call when the instruction is executed.
  // std::unordered_set<InstProperty> properties; ///< Properties specific to this instruction.

  OperatorDef(
    const std::string& _name,
    // inst_fun_t _fun_call,
    const std::string& _desc
    // const std::unordered_set<InstProperty>& _properties={}
  ) :
    name(_name),
    desc(_desc)
  { ; }

  OperatorDef(const OperatorDef&) = default;
};

template<typename HARDWARE_T>
class OperatorLibrary {
public:
  using op_def_t = OperatorDef;
protected:
  emp::vector<op_def_t> op_lib;               // Full definitions of each operation type
  std::map<std::string, size_t> op_name_map;  // Mapping from operator name to op id in op_lib
  size_t max_op_inputs = 0;

public:
  OperatorLibrary() : op_lib(), op_name_map() { ; }
  OperatorLibrary(const OperatorLibrary&) = delete;
  OperatorLibrary(OperatorLibrary&&) = delete;
  ~OperatorLibrary() { ; }

  // Remove all operators from the operator library
  void Clear() {
    op_lib.clear();
    op_name_map.clear();
    max_op_inputs = 0;
  }

  /// Return the name associated with the specified operator ID.
  const std::string& GetName(size_t id) const { return op_lib[id].name; }

  /// Return the function associated with the specified operator ID.
  // const inst_fun_t& GetFunction(size_t id) const { return inst_lib[id].fun_call; }

  /// Return the provided description for the provided operator ID.
  const std::string& GetDesc(size_t id) const { return op_lib[id].desc; }

  /// Return number of inputs for a givevn operator
  size_t GetNumInputs(size_t id) { return op_lib[id].num_inputs; }

  /// @return Maximum number of inputs used across all operators in this operator library
  size_t GetMaxNumOperatorInputs() { return max_op_inputs; }

  /// Get the number of operators in this set.
  size_t GetSize() const { return op_lib.size(); }

  /// Return the ID of the operator that has the specified name.
  size_t GetID(const std::string& name) const {
    emp_assert(emp::Has(op_name_map, name), name);
    return emp::Find(op_name_map, name, (size_t)-1);
  }

  void AddOperator(const op_def_t& definition) {
    // Should not add a duplicate operator.
    emp_assert(!emp::Has(op_name_map, definition.name));
    const size_t id = op_lib.size();
    op_lib.emplace_back(definition);
    op_name_map[definition.name] = id;
  }

  // TODO
  // void RunOperator()

};

}