var tsl = {
  columns: [
    ['motion_tx',0.020 ,0.075 ,0.045 ,0.087 ,0.052 ,0.023 ,0.011 ,0.024 ,-0.009 ,-0.049 ,-0.058 ,0.020 ,-0.017 ,0.007 ,-0.012 ,-0.028 ,-0.023 ,-0.040 ,-0.028 ,0.001 ,-0.008 ,0.001 ,0.034 ,0.027 ,0.025 ,0.014 ,0.018 ,0.020 ,0.031 ,0.012 ],
    ['motion_ty',-0.012 ,-0.012 ,0.017 ,-0.003 ,-0.006 ,-0.028 ,-0.001 ,-0.016 ,0.003 ,0.001 ,0.022 ,-0.007 ,0.045 ,-0.008 ,-0.073 ,-0.037 ,-0.020 ,0.022 ,0.014 ,-0.012 ,-0.021 ,-0.047 ,-0.003 ,-0.039 ,-0.049 ,0.004 ,-0.017 ,0.017 ,-0.011 ,0.000 ],
    ['motion_tz',-0.266 ,-0.126 ,-0.106 ,-0.093 ,0.009 ,-0.038 ,-0.002 ,-0.006 ,0.005 ,0.061 ,0.007 ,-0.184 ,-0.001 ,0.028 ,0.091 ,0.109 ,0.122 ,0.108 ,0.095 ,0.063 ,0.054 ,0.005 ,-0.136 ,0.011 ,0.006 ,-0.015 ,-0.008 ,0.064 ,0.075 ,0.066 ]
  ],
  selection: {
    enabled: true
  },
  onclick: function (d) { selectTime(d.index);}
};

var rot = {
  columns: [
    ['motion_rx',-0.340 ,-0.114 ,-0.091 ,-0.132 ,-0.137 ,-0.127 ,-0.069 ,-0.034 ,-0.043 ,-0.013 ,-0.060 ,-0.174 ,0.003 ,-0.009 ,0.044 ,0.083 ,0.090 ,0.108 ,0.098 ,0.070 ,0.082 ,0.011 ,-0.131 ,0.049 ,0.020 ,0.050 ,0.038 ,0.107 ,0.093 ,0.084 ],
    ['motion_ry',0.070 ,0.001 ,0.048 ,0.034 ,0.036 ,0.035 ,0.016 ,-0.029 ,-0.012 ,-0.037 ,-0.020 ,0.027 ,0.033 ,-0.095 ,-0.137 ,-0.036 ,0.030 ,-0.003 ,-0.010 ,0.012 ,-0.027 ,-0.018 ,0.018 ,-0.038 ,-0.040 ,-0.019 ,-0.041 ,-0.036 ,-0.015 ,-0.007 ],
    ['motion_rz',-0.034 ,-0.044 ,-0.004 ,-0.053 ,-0.037 ,-0.011 ,0.001 ,-0.017 ,0.027 ,0.026 ,0.055 ,-0.016 ,0.032 ,-0.019 ,-0.046 ,0.029 ,0.017 ,0.024 ,0.024 ,-0.012 ,-0.010 ,-0.011 ,-0.045 ,-0.019 ,-0.047 ,-0.056 ,-0.059 ,-0.037 ,-0.011 ,-0.053 ]
  ],
  selection: {
    enabled: true
  },
  onclick: function (d) { selectTime(d.index);}
};

var fd = {
  columns: [
    ['FD',0.462 ,0.176 ,0.166 ,0.159 ,0.131 ,0.152 ,0.119 ,0.127 ,0.146 ,0.166 ,0.504 ,0.477 ,0.277 ,0.255 ,0.258 ,0.110 ,0.124 ,0.048 ,0.166 ,0.074 ,0.153 ,0.405 ,0.420 ,0.068 ,0.139 ,0.065 ,0.192 ,0.105 ,0.092 ,0 ],
    ['scrub',0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,1 ,1 ,1 ,1 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ]
  ],
  selection: {
    enabled: true
  },
  onclick: function (d) { selectTime(d.index);}
};
