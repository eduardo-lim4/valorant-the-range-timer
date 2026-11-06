using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public sealed class HotkeyEventArgs : EventArgs
{
    public int Id { get; private set; }
    public HotkeyEventArgs(int id) { Id = id; }
}

public sealed class HotkeyCaptureEventArgs : EventArgs
{
    public int Key { get; private set; }
    public int Modifiers { get; private set; }
    public HotkeyCaptureEventArgs(int key, int modifiers) { Key = key; Modifiers = modifiers; }
}

public sealed class HotkeyCaptureButton : Button
{
    public bool Capturing { get; set; }
    public event EventHandler<HotkeyCaptureEventArgs> ShortcutCaptured;

    [DllImport("user32.dll")]
    private static extern short GetKeyState(int key);

    private void CaptureShortcut(Keys data)
    {
        int key = (int)(data & Keys.KeyCode);
        if (key == 0 || key == 16 || key == 17 || key == 18 ||
            (key >= 160 && key <= 165) || key == 91 || key == 92)
            return;
        int modifiers = 0;
        if ((data & Keys.Alt) != 0) modifiers |= 1;
        if ((data & Keys.Control) != 0) modifiers |= 2;
        if ((data & Keys.Shift) != 0) modifiers |= 4;
        if ((GetKeyState(91) & 0x8000) != 0 || (GetKeyState(92) & 0x8000) != 0) modifiers |= 8;
        Capturing = false;
        if (ShortcutCaptured != null)
            ShortcutCaptured(this, new HotkeyCaptureEventArgs(key, modifiers));
    }

    protected override bool IsInputKey(Keys keyData)
    {
        return Capturing || base.IsInputKey(keyData);
    }

    protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
    {
        if (!Capturing) return base.ProcessCmdKey(ref msg, keyData);
        CaptureShortcut(keyData);
        return true;
    }

    protected override void OnKeyDown(KeyEventArgs e)
    {
        if (Capturing)
        {
            CaptureShortcut(e.KeyData);
            e.Handled = true;
            e.SuppressKeyPress = true;
            return;
        }
        base.OnKeyDown(e);
    }
}

public sealed class RangeHotkeys : NativeWindow, IDisposable
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr handle, int id, uint modifiers, uint key);
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr handle, int id);

    private readonly Dictionary<int, int[]> bindings = new Dictionary<int, int[]>();
    private readonly HashSet<int> registered = new HashSet<int>();
    private bool active;
    public string LastError { get; private set; }
    public event EventHandler<HotkeyEventArgs> Pressed;

    public RangeHotkeys()
    {
        CreateHandle(new CreateParams());
    }

    public int GetKey(int id) { return bindings.ContainsKey(id) ? bindings[id][0] : 0; }
    public int GetModifiers(int id) { return bindings.ContainsKey(id) ? bindings[id][1] : 0; }
    public bool IsRegistered(int id) { return registered.Contains(id); }

    public bool SetBinding(int id, int key, int modifiers)
    {
        LastError = null;
        if (id < 1 || id > 4 || modifiers < 0 || modifiers > 7 || key < 0 || key > 254 ||
            key == 16 || key == 17 || key == 18 || (key >= 160 && key <= 165) ||
            key == 91 || key == 92 || key == 123)
        {
            LastError = "Escolha uma tecla valida. F12, a tecla Windows e modificadores isolados nao sao permitidos.";
            return false;
        }
        if (key == 0)
        {
            if (registered.Remove(id)) UnregisterHotKey(Handle, id);
            bindings.Remove(id);
            return true;
        }
        foreach (KeyValuePair<int, int[]> binding in bindings)
        {
            if (binding.Key != id && binding.Value[0] == key && binding.Value[1] == modifiers)
            {
                LastError = "Este atalho ja esta atribuido a outra acao.";
                return false;
            }
        }
        if (GetKey(id) == key && GetModifiers(id) == modifiers) return true;
        if (!RegisterHotKey(Handle, 100, (uint)(modifiers | 0x4000), (uint)key))
        {
            LastError = "O Windows nao permitiu registrar este atalho. Ele pode estar em uso ou ser reservado.";
            return false;
        }
        UnregisterHotKey(Handle, 100);
        int[] previous = bindings.ContainsKey(id) ? bindings[id] : null;
        bool wasRegistered = registered.Remove(id);
        if (wasRegistered) UnregisterHotKey(Handle, id);
        if (active && !RegisterHotKey(Handle, id, (uint)(modifiers | 0x4000), (uint)key))
        {
            if (wasRegistered && RegisterHotKey(Handle, id, (uint)(previous[1] | 0x4000), (uint)previous[0]))
                registered.Add(id);
            LastError = "O atalho nao pode ser ativado agora. A configuracao anterior foi mantida.";
            return false;
        }
        bindings[id] = new[] { key, modifiers };
        if (active) registered.Add(id);
        return true;
    }

    public void RestoreBinding(int id, int key, int modifiers)
    {
        if (id < 1 || id > 4 || key <= 0 || key > 254 || modifiers < 0 || modifiers > 7 ||
            key == 16 || key == 17 || key == 18 || (key >= 160 && key <= 165) || key == 91 || key == 92 || key == 123)
            return;
        foreach (KeyValuePair<int, int[]> binding in bindings)
            if (binding.Value[0] == key && binding.Value[1] == modifiers) return;
        bindings[id] = new[] { key, modifiers };
    }

    public int[] Activate()
    {
        active = true;
        List<int> failed = new List<int>();
        foreach (KeyValuePair<int, int[]> binding in bindings)
        {
            if (registered.Contains(binding.Key)) continue;
            if (RegisterHotKey(Handle, binding.Key, (uint)(binding.Value[1] | 0x4000), (uint)binding.Value[0]))
                registered.Add(binding.Key);
            else
                failed.Add(binding.Key);
        }
        return failed.ToArray();
    }

    public void Deactivate()
    {
        active = false;
        foreach (int id in registered) UnregisterHotKey(Handle, id);
        registered.Clear();
    }

    public string GetDisplay(int id)
    {
        if (!bindings.ContainsKey(id)) return "Sem atalho";
        int[] binding = bindings[id];
        string text = "";
        if ((binding[1] & 2) != 0) text += "Ctrl + ";
        if ((binding[1] & 1) != 0) text += "Alt + ";
        if ((binding[1] & 4) != 0) text += "Shift + ";
        return text + new KeysConverter().ConvertToString((Keys)binding[0]);
    }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == 0x0312 && registered.Contains(message.WParam.ToInt32()))
        {
            if (Pressed != null) Pressed(this, new HotkeyEventArgs(message.WParam.ToInt32()));
            return;
        }
        base.WndProc(ref message);
    }

    public void Dispose()
    {
        Deactivate();
        DestroyHandle();
    }
}
