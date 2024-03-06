using System;

namespace Data
{
    [Serializable]
    public class Statistics
    {
        public CPUData cpu;
        public MemoryData memory;
        public GPUData gpu;
    }
}