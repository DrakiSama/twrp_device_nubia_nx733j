#!/usr/bin/env python3
"""Exercise actual data.cpp default setup and CPU reading with simulated time/I/O."""
from pathlib import Path
import subprocess
import tempfile
import sys

source = Path(sys.argv[1]).read_text(encoding='utf-8')
start = source.index('#ifdef TW_NO_CPU_TEMP')
setup = source[start:source.index('#ifdef TW_CUSTOM_POWER_BUTTON', start)]
if 'else if (varName == "tw_cpu_temp")' in source:
    start = source.index('else if (varName == "tw_cpu_temp")')
    end = source.index('\n\treturn -1;\n}', start)
    read = source[start:end].replace('else if', 'if', 1)
else:
    start = source.index('if (key == "tw_cpu_temp")')
    end = source.index('\n  return -1;\n}', start)
    read = source[start:end].replace('if (key ==', 'if (varName ==', 1)
prefix = r'''
#include <cassert>
#include <charconv>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <string>
#include <sys/time.h>
using std::string;
#define EXPAND(x) x
#define LOGINFO(...) ((void)0)
bool available=false;
int reads=0;
int disabled=1;
time_t now=100;
int fake_time(timeval* tv, void*) {tv->tv_sec=now;return 0;}
#define gettimeofday fake_time
struct Store {
 void SetValue(const char*,const char* value){disabled=atoi(value);}
 int& operator[](const string&){return disabled;}
} mConst, consts_;
void GetValue(const char*,int& value){value=disabled;}
namespace fs {bool exists(const string&){return available;}}
namespace TWFunc {
bool Path_Exists(const string&){return available;}
int read_file(const string&,string& value){++reads;if(!available)return -1;value="43000";return 0;}
string to_string(unsigned long value){return std::to_string(value);}
}
namespace android { namespace base {
bool ReadFileToString(const string&,string* value){++reads;if(!available)return false;*value="43000\n";return true;}
}}
void setup() {
'''
suffix = r'''
int main(){
 setup();
 string value="unavailable";
#if defined(TW_CUSTOM_CPU_TEMP_PATH) && !defined(TW_NO_CPU_TEMP)
 assert(disabled==0);
 assert(read_cpu("tw_cpu_temp",value)==-1);
 assert(value=="unavailable" && reads==1);
 available=true; ++now;
 assert(read_cpu("tw_cpu_temp",value)==0 && value=="43" && reads==2);
 // Once available, the existing five-second cache remains intact.
 assert(read_cpu("tw_cpu_temp",value)==0 && reads==2);
#else
 assert(disabled==1);
 assert(read_cpu("tw_cpu_temp",value)==-1 && reads==0);
 available=true; setup();
#ifdef TW_NO_CPU_TEMP
 assert(disabled==1);
 assert(read_cpu("tw_cpu_temp",value)==-1 && reads==0);
#else
 assert(disabled==0);
 assert(read_cpu("tw_cpu_temp",value)==0 && value=="43");
#endif
#endif
 puts("CPU sensor scenario passed");
}
'''
with tempfile.TemporaryDirectory() as temp:
    cpp = Path(temp) / 'cpu.cpp'
    cpp.write_text(prefix + setup + '\n}\nint read_cpu(const string& varName,string& value){\n' + read + '\nreturn -1;\n}\n' + suffix, encoding='utf-8')
    for flags in [[], ['-DTW_CUSTOM_CPU_TEMP_PATH="/tmp/nx733j-cpu-temp"'],
                  ['-DTW_NO_CPU_TEMP', '-DTW_CUSTOM_CPU_TEMP_PATH="/tmp/nx733j-cpu-temp"']]:
        binary = Path(temp) / 'cpu'
        subprocess.run(['g++', '-std=c++17', '-Wall', '-Wextra', '-Werror', *flags, str(cpp), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True)
