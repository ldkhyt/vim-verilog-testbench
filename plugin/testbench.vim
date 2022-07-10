" A simple script for generating verilog testbench and instance
" Time   : 2022.07.10
" Author : ldkhyt

if has("python3")
    let g:pyv = "py3"
else
    echoe "Error: This plugin need +python3"
    finish
endif

:nnoremap <leader>tb :call Generate_tb()<cr>
function! Generate_tb()
python3 << EOF

import re
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
    # print(parameters)
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
        instance_text = ["{0} #(\n".format(mod_name)]
    else:
        instance_text = ["{0} #(\n".format(mod_name)]

        for para_i in parameters:
            (para_name, para_value) = para_i[-1].split("=")
            if max_parameter_len < len(para_name):
                max_parameter_len = len(para_name)
            if max_parameter_value_len < len(para_value):
                max_parameter_value_len = len(para_value)
        for para_i in parameters:
            (para_name, para_value) = para_i[-1].split("=")
            parameter_str = "\t.{0:<{2}}({1:<{3}}),\n".format(para_name, para_value, max_parameter_len+6, max_parameter_value_len+6)
            instance_text.append(parameter_str)
        instance_text[-1] = instance_text[-1][:-2] + '\n'

    instance_text.append(") u_{0} (\n".format(mod_name))

    max_signal_name_len = 4
    max_signal_bitwidth_len = 4
    for signal_i in signals:
        if len(signal_i[-1]) > max_signal_name_len:
            max_signal_name_len = len(signal_i[-1])
        if len(signal_i[-1]) > max_signal_bitwidth_len:
            max_signal_bitwidth_len = len(signal_i[-1])

    for signal_i in signals:
        instance_text.append("\t.{0:<{1}}({0:<{1}}),\n".format(signal_i[-1], max_signal_name_len+6))
    instance_text[-1] = instance_text[-1][:-2] + '\n'
    instance_text.append(");\n\n")

    # print(instance_text)
    return instance_text, (max_parameter_len, max_parameter_value_len, max_signal_name_len, max_signal_bitwidth_len)


def create_tb(modname, signals, parameters):
    tb_file = open("tb_{0}.v".format(modname), 'w')
    if not tb_file:
        print("Create file failed!")
        return None

    # module tb_modname;
    tb_file.write("`timescale 1ns/1ps\n")
    tb_file.write("module tb_{0};\n".format(modname))
    tb_file.write("// ---- Ports\n")

    instance_text, max_len = create_instance(modname, signals, parameters)

    has_clk = False
    has_rst_n = False

    # create a default parameter table for bit width with parameters
    parameters_table = {}
    for pars_i in parameters:
        if '=' in pars_i[-1]:
            default_pars = pars_i[-1].split('=')
            parameters_table[default_pars[0].strip()] = default_pars[1].strip()

    for signal_i in signals:
        if signal_i[-1] == "clk":
            has_clk = True
        if signal_i[-1] == "rst_n":
            has_rst_n = True

        bitwidth = signal_i[1]
        for pars_i in parameters_table:
            if pars_i in signal_i[1]:
                bitwidth = signal_i[1].replace(pars_i, parameters_table[pars_i])

        format_bitwidth = "{0:<{1}}".format(bitwidth, max_len[3]+6)
        format_signal_name = "{0:<{1}}".format(signal_i[2], max_len[2]+6)
        if signal_i[0] == "input":
            tb_file.write("reg     " + format_bitwidth + signal_i[2] + ";\n")
        else:
            tb_file.write("wire    " + format_bitwidth + signal_i[2] + ";\n")

    if has_clk:
        tb_file.write("\nparameter PERIOD = 10;\n")
        tb_file.write("initial begin\n")
        tb_file.write("\tclk = 0;\n")
        tb_file.write("\tforever #(PERIOD/2) clk = ~clk;\n")
        tb_file.write("end\n\n")

    if has_rst_n:
        tb_file.write("\ninitial begin\n")
        tb_file.write("\trst_n=0;\n")
        tb_file.write("\t#(PERIOD) rst_n = 1;\n")
        tb_file.write("end\n\n")

    tb_file.write("\n")
    for ins_i in instance_text:
        tb_file.write(ins_i)

    tb_file.write("initial begin\n\n")
    tb_file.write("\n#100 $finish;\n")
    tb_file.write("end\n\n")

    tb_file.write("initial begin\n")
    tb_file.write("\t$dumpfile(\"wave.vcd\");\n")
    tb_file.write("\t$dumpvars(0, tb_{0});\n".format(modname))
    tb_file.write("end\n\n\nendmodule")

    tb_file.close()

    return "tb_{0}.v".format(modname)


def get_file_path():
    vim.command("w")
    file_path = vim.current.buffer.name
    return file_path

def TB():
    module_info = analyze_module(remove_comment(read_file(get_file_path())))
    if module_info:
        outfile = create_tb(module_info[0], module_info[1], module_info[2])
    vim.command("vsplit %s" % outfile)

TB()

EOF

endfunction
