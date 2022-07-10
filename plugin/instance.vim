" A simple script for generating verilog testbench and instance
" Time   : 2022.07.10
" Author : ldkhyt

if has("python3")
    let g:pyv = "py3"
else
    echoe "Error: This plugin need +python3"
    finish
endif

:nnoremap <leader>in :call Generate_Instance()<cr>
function! Generate_Instance()
python3 << EOF

import re
import os
import vim


def read_file(filename):
    if filename[-2:] != '.v':
        return None
    f = open(filename, 'r')
    text = f.read()
    f.close()
    return text


# remove the comment of verilog code // and /**/
def remove_comment(text):
    if not text:
        return None
    ret = re.compile("//.*|/\*[\w\W]*?\*/")
    text = re.sub(ret, '', text)
    # print(text)
    return text


def analyze_module(text):
    if not text:
        return None
    """extracted necessary information from source code"""
    # Step 1: get mod name
    # Step 2: get signal information
    # Step 3: get parameters

    # ----------------STEP 1-------------------------------
    modname_re = re.compile("(module\s+)([a-zA-Z_]+[\w]*)")
    try:
        res = re.search(modname_re, text)
        mod_name = res.group(2)
    except:
        return None

    # ----------------STEP 2-------------------------------
    # input/output/inout + signal name + bitwidth
    signal_re = re.compile("(output|input|inout)\s*(?:wire|reg)?\s+(\[.+\])?\s*([a-zA-Z_][a-zA-Z0-9_]*.*)\s*;")
    # for verilog 2001
    signal_re2 = re.compile("(output|input|inout)\s*(?:wire|reg)?\s*(\[.+\])?\s*([a-zA-Z_]+[\w]*[^;]*?)\s*(?=output|input|\))")
    try:
        signal_1 = re.findall(signal_re, text)
        signal_2 = re.findall(signal_re2, text)
        # print(signal_1)
        # print(signal_2)
        ori_signals =  signal_1 + signal_2
        signals = []
        for i in range(len(ori_signals)):
            if ',' in ori_signals[i][-1]:
                for si_name in ori_signals[i][-1].split(","):
                    if si_name:
                        signals.append((ori_signals[i][0], ori_signals[i][1], si_name.strip()))
            else:
                signals.append(ori_signals[i])
        # print(signals)
    except:
        return None

    # ----------------STEP 3------------------------------
    # defparm all the parameter in the module
    parameter_re = re.compile("(parameter)\s+([a-zA-Z_]+[\w]*\s*=\s*.*?)\s*(?=[;,)])")

    parameters = re.findall(parameter_re, text)
    print(parameters)
    return mod_name, signals, parameters


def create_instance(mod_name, signals, parameters):
    # modname #(
    #   .parameter1(parameter1),
    #   .parameter2(parameter2)
    # ) u_modname (
    #   .output1(output1),
    #   .input1(input1)
    # )
    if not (mod_name and signals):
        return None

    max_parameter_len = 0
    max_parameter_value_len = 0
    if len(parameters) == 0:
        instance_text = ["{0} #(".format(mod_name)]
    else:
        instance_text = ["{0} #(".format(mod_name)]

        for para_i in parameters:
            (para_name, para_value) = para_i[-1].split("=")
            if max_parameter_len < len(para_name):
                max_parameter_len = len(para_name)
            if max_parameter_value_len < len(para_value):
                max_parameter_value_len = len(para_value)
        for para_i in parameters:
            (para_name, para_value) = para_i[-1].split("=")
            parameter_str = "\t.{0:<{2}}({1:<{3}}),".format(para_name, para_value, max_parameter_len+6, max_parameter_value_len+6)
            instance_text.append(parameter_str)
        instance_text[-1] = instance_text[-1][:-1] 

    instance_text.append(") u_{0} (".format(mod_name))

    max_signal_name_len = 4
    max_signal_bitwidth_len = 4
    for signal_i in signals:
        if len(signal_i[-1]) > max_signal_name_len:
            max_signal_name_len = len(signal_i[-1])
        if len(signal_i[-1]) > max_signal_bitwidth_len:
            max_signal_bitwidth_len = len(signal_i[-1])

    for signal_i in signals:
        instance_text.append("\t.{0:<{1}}({0:<{1}}),".format(signal_i[-1], max_signal_name_len+6))
    instance_text[-1] = instance_text[-1][:-1] 
    instance_text.append(");")

    # print(instance_text)
    return instance_text, (max_parameter_len, max_parameter_value_len, max_signal_name_len, max_signal_bitwidth_len)

# Get the word on the cursor as the module name we want to instance
def get_current_modname():
    vim.command("w")
    modname = vim.eval("expand(\"<cword>\")")
    return modname

# Find the file {modname.v} in current directory
def search_mod():
    modname = get_current_modname()
    current_file = vim.current.buffer.name
    # get current dir
    cdir = os.path.dirname(current_file)
    file_info = os.walk(cdir)
    cur_file_info = file_info.__next__()
    filename_in_dir = cur_file_info[2]
    for fn_i in filename_in_dir:
        if modname+'.v' == fn_i:
            mod_file = os.path.join(cdir, fn_i)
            return mod_file
    return None

def INSTANCE():
    mod_file = search_mod()
    # print(mod_file)
    if not mod_file:
        print("Error: Please Put the cursor on a module name.")
        return None
    module_info = analyze_module(remove_comment(read_file(mod_file)))
    # print(module_info)
    if module_info:
        instance_text, _ = create_instance(module_info[0], module_info[1], module_info[2])
    else:
        print("Error: Analyze module {} failed.".format(mod_file))
        return None
    # print(instance_text)
    cur_line = int(vim.eval("line(\".\")"))
    vim.current.line = instance_text[0]
    vim.command('w')
    for ins_i in range(1, len(instance_text)):
        # print(instance_text[ins_i])
        vim.current.buffer.append(instance_text[ins_i], cur_line)
        cur_line += 1
INSTANCE()

EOF

endfunction
