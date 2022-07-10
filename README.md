
# vim-verilog-testbench
> Author: ldkhyt
> 
> LICENCE: MIT


## Usage: 

### Install
+python3 is needed.
Install this plugin by "vim-plug"
Add this statement in your vimrc file:

```vimscript
Plug 'ldkhyt/vim-verilog-testbench'
```

Then save your vimrc file and input the command `:PlugInstall` 

### Generate testbench
You can type `<leader>tb` in normal mode of a "modulename.v" file. 

The file "tb_modulename.v" will be generated. 

### Generate instance

When you are editing a file and want to instantiate a module, first enter the module name, then place the cursor on the module name, and enter the shortcut key `<leader>in` in Normal mode

The the instance of the module will be generated if the module as a single file can be searched in current directory.

## Postscript

The `$dumpfile` in testbench is set for Iverilog and GTKwave in default case.

Only simple tests have been done in this plugin. I will update it according to my future work experience.

# 使用说明
## 用法
安装这个插件需要使用插件管理器"vim-plug"

增加这个语句在vimrc文件中
```vimscript
Plug 'ldkhyt/vim-verilog-testbench'
```
然后使用命令`:PlugInstall` 安装

### 生成testbench文件
输入快捷键`<leader>tb` 当当前缓冲区是verilog module文件，且vim处于Normal模式, 一个testbench文件就会被生成.

### 模块例化
当你正在编辑一个文件，想例化某个模块，先输入模块名，然后将光标置于模块名上，在Normal模式下输入快捷键`<leader>in`

## 补充说明
生成的tb文件的`$dumpfile`的写法默认对Iverilog和GTKwave使用。
该插件仅仅进行了简单的测试，未来依据工作经验做进一步的更新。
