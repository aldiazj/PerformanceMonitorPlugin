using System;
using System.Collections.Generic;

namespace Data
{
    [Serializable]
    public class RawData
    {
        public List<double> gpu;
        public List<double> cpu;
        public List<double> memory;
    }
}