using System;
using System.Runtime.InteropServices;
using Data;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class PerformanceMonitor : MonoBehaviour
{
    [SerializeField] private Button startButton;
    [SerializeField] private Button stopButton;
    [SerializeField] private TextMeshProUGUI textMesh;
    
    public bool isTracking;

    [DllImport("__Internal")]
    private static extern void startTracking();
    
    [DllImport("__Internal")]
    private static extern void monitorDevice();
    
    [DllImport("__Internal")]
    private static extern IntPtr stopTracking();
    
    private void Awake()
    {
        startButton.onClick.AddListener(StartTracking);
        stopButton.onClick.AddListener(StopTracking);
    }
    
    private void Update()
    {
        if (!isTracking)
        {
            return;
        }
        monitorDevice();
    }

    private void OnDestroy()
    {
        startButton.onClick.RemoveListener(StartTracking);
        stopButton.onClick.RemoveListener(StopTracking);
    }

    private void StartTracking()
    {
        isTracking = true;
        textMesh.text = "";
        startTracking();
    } 
    
    private void StopTracking()
    {
        isTracking = false;
    
        IntPtr rawDataPtr = stopTracking();
        if (rawDataPtr != IntPtr.Zero)
        {
            string rawDataJson = Marshal.PtrToStringAuto(rawDataPtr);
            Marshal.FreeHGlobal(rawDataPtr); 

            Debug.Log("Raw data JSON: " + rawDataJson);

            PerformanceData data = JsonUtility.FromJson<PerformanceData>(rawDataJson);
        
            string displayText = $"CPU Usage:\nMin: {data.statistics.cpu.min}%\nMax: {data.statistics.cpu.max}%\nAverage: {data.statistics.cpu.average}%\n95th Percentile: {data.statistics.cpu.percentile95}%\n\n" +
                                 $"Memory Usage:\nMin: {data.statistics.memory.min} MB\nMax: {data.statistics.memory.max} MB\nAverage: {data.statistics.memory.average} MB\n95th Percentile: {data.statistics.memory.percentile95} MB";
            textMesh.text = displayText;
        }
    }
}