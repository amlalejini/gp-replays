import csv
import errno
import os

def mkdir_p(path):
    """
    This is functionally equivalent to the mkdir -p [fname] bash command
    """
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

def read_csv(file_path):
    """
    Read content of csv file into a list where each entry in the list is a dictionary
    with header:value entries.
    """
    content = None
    with open(file_path, "r") as fp:
        content = fp.read().strip().split("\n")
    header = content[0].split(",")
    content = content[1:]
    lines = [
        {header[i]: l[i] for i in range(len(header))}
        for l in csv.reader(
            content,
            quotechar='"',
            delimiter=',',
            quoting=csv.QUOTE_ALL,
            skipinitialspace=True
        )
    ]
    return lines

def append_csv(output_path, out_lines, field_order):
    lines = []
    for info in out_lines:
        line = ",".join([str(info[field]) for field in field_order])
        lines.append(line)
    out_content = "\n" + "\n".join(lines)
    with open(output_path, "a") as fp:
        fp.write(out_content)

def write_csv(output_path:str, rows:list):
    header = list(rows[0].keys())
    header.sort()
    lines = [ ",".join([str(row[field]) for field in header]) for row in rows ]
    with open(output_path, "w") as fp:
        fp.write(",".join(header) + "\n")
        fp.write("\n".join(lines))

def nearest(target:int, updates:list):
    return min(updates, key = lambda x:abs(target - x))

def filter_time_points(all_points, method, resolution):
    if method == "total":
        return filter_time_points_total(all_points, resolution)
    elif method == "interval":
        return filter_time_points_interval(all_points, resolution)
    else:
        return None

def filter_time_points_total(all_points, total):
    '''
    Given a sequence of points,
    sort points and sample 'total' amount of them, evenly distributed.
    '''
    sorted_points = sorted(all_points)
    ids = { i * ((len(all_points) - 1) // (total - 1)) for i in range(total)}

    ids = sorted(list(ids))
    # If last id isn't final index, make it so.
    if ids[-1] != (len(sorted_points) - 1):
        ids[-1] = len(sorted_points) - 1

    return [sorted_points[idx] for idx in ids]

def filter_time_points_interval(all_points, interval, guarantee_final_point=True):
    '''
    Given a sequence of points, sample sorted sequence at given interval.
    Guarant
    '''
    sorted_points = sorted(all_points)
    return [
        sorted_points[i] for i in range(len(sorted_points))
        if (i == 0) or (not (i % interval)) or (guarantee_final_point and (i == (len(sorted_points) - 1)))
    ]