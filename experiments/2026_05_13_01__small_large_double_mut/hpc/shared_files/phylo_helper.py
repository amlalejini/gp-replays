import sys
import csv

def convert_genotype(old_lines):
    s = '{'
    for line in old_lines:
        line = line.strip()
        if 'Fn' in line:
            tag, fname = line.split()
            tag = tag.strip('(').strip(')')
            function_num = fname.split('-')[-1]
            s += f'{function_num}[{tag}]:'
        elif line == '':
            continue
        else:
            parts = line.split()
            tag = parts[0]
            inst_name = parts[1]
            nums = ' '.join(parts[2:])
            tag = tag.strip('(').strip(')')
            nums = nums.strip('[').strip(']').replace(' ', '')
            s += f'{inst_name}({nums})[{tag}];'
    if s[-1] == ';':
        s = s[:-1]
    s += '}\n'
    return s

def create_file(genotype, filename, pop_size):
    converted_genotype = convert_genotype(genotype)
    with open(filename, 'w') as fp:
        for i in range(pop_size):
            fp.write(converted_genotype)
    

    

if __name__ == '__main__':
    if len(sys.argv) != 6:
        print('Error! Expected exactly five arguments:')
        print('  1. Path to phylo csv file')
        print('  2. Path to phylo genotypes csv file')
        print('  3. Generations to extract (comma separated + inclusive ranges with -)')
        print('  4. Output filename prefix')
        print('  5. Target population size')
        sys.exit(1)

    phylo_filename = sys.argv[1]
    genotype_filename = sys.argv[2]
    generation_str = sys.argv[3]
    output_filename_prefix = sys.argv[4]
    pop_size = int(sys.argv[5])

    phylo_data = {}
    extant_orgs = []
    max_gen = 0
    dom_org = None
    with open(phylo_filename, 'r') as phylo_fp:
        reader = csv.DictReader(phylo_fp)
        for row in reader:
            taxa_id = row['id']
            phylo_data[taxa_id] = row
            max_gen = max(max_gen, int(row['origin_time']))
            if row['destruction_time'] == 'inf':
                extant_orgs.append(row)
                if dom_org is None or int(dom_org['num_orgs']) < int(row['num_orgs']):
                    dom_org = row

    print(f'Total taxa: {len(phylo_data)}')
    print(f'Extant taxa: {len(extant_orgs)}')
    print(f'Max gen: {max_gen}')
    print(f'Dominant org: {dom_org}')

    gen_to_id_dict = {}
    cur_org = dom_org
    while cur_org['ancestor_list'] != '[NONE]':
        gen = int(cur_org['origin_time'])
        gen_to_id_dict[gen] = cur_org['id']
        print(f'{cur_org["id"]}({cur_org["origin_time"]}) -> ', end = '')
        ancestor_id = cur_org['ancestor_list'].strip().strip('[').strip(']')
        cur_org = phylo_data[ancestor_id]
    gen = int(cur_org['origin_time'])
    gen_to_id_dict[gen] = cur_org['id']
    print(f'{cur_org["id"]}({cur_org["origin_time"]})')

    genotypes = {}
    cur_id = None
    cur_genotype = []
    with open(genotype_filename, 'r') as genotype_fp:
        for line in genotype_fp:
            if line.strip() == '':
                if cur_id is not None and len(cur_genotype) > 0:
                    genotypes[cur_id] = cur_genotype
                    cur_id = None
                    cur_genotype = []
            elif line[0] == '!':
                cur_id = line.strip().strip('!')
                print(f'Found id: {cur_id}')
            else:
                cur_genotype.append(line.rstrip())

    dom_genotype = genotypes[dom_org['id']]
    
    print(dom_genotype)
    print(convert_genotype(dom_genotype))

    for gens in generation_str.split(','):
        if '-' in gens:
            if gens.count('-') > 1:
                print('Error! Can only have one - per comma separated group of generations')
                sys.exit(1)
            min_gen, max_gen = gens.split('-')
            for gen in range(int(min_gen), int(max_gen) + 1):
                if gen not in gen_to_id_dict.keys():
                    print(f'Cannot create file for gen {gen}: no genotypes found for gen')
                    continue
                org_id = gen_to_id_dict[gen]
                genotype = genotypes[org_id]
                filename = f'{output_filename_prefix}__gen_{gen}.dat'
                create_file(genotype, filename, pop_size)
        else:
            gen = int(gens)
            if gen not in gen_to_id_dict.keys():
                print(f'Cannot create file for gen {gen}: no genotypes found for gen')
                continue
            org_id = gen_to_id_dict[gen]
            genotype = genotypes[org_id]
            filename = f'{output_filename_prefix}__gen_{gen}.dat'
            create_file(genotype, filename, pop_size)

                

