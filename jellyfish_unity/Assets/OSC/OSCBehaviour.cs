using System;
using System.Collections.Generic;
using extOSC;
using UnityEngine.Events;
using UnityEngine;

public class OscSinkBase : MonoBehaviour {
    private static OSCManager _manager;
    protected List<string> BoundAddresses;

    protected void BindReceive(string address, UnityAction<OSCMessage> action) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        var a = _manager.BindToReceiver("/" + gameObject.name, address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
    protected void BindReceiveGlobal(string address, UnityAction<OSCMessage> action) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        var a = _manager.BindToGlobal(address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
}

public class OscSrcBase : MonoBehaviour {
    private static OSCManager _manager;

    protected void BindTransmit(string address, Func<float> getter) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        _manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector2> getter) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        _manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector3> getter) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        _manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
}

public class OscSinkAndSrcBase : MonoBehaviour {
    private static OSCManager _manager;
    protected List<string> BoundAddresses;
    
    protected void BindReceive(string address, UnityAction<OSCMessage> action) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        var a = _manager.BindToReceiver("/" + gameObject.name, address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
    protected void BindReceiveGlobal(string address, UnityAction<OSCMessage> action) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        var a =_manager.BindToGlobal(address, action);
        if (BoundAddresses == null)
            BoundAddresses = new List<string>();
        BoundAddresses.Add(a);
    }
    
    protected void BindTransmit(string address, Func<float> getter) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        _manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector2> getter) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        _manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
    protected void BindTransmit(string address, Func<UnityEngine.Vector3> getter) {
        if (_manager == null)
            _manager = GameObject.Find("GameManager").GetComponent<OSCManager>();
        _manager.BindToTransmitter("/" + gameObject.name + address, getter);
    }
}
