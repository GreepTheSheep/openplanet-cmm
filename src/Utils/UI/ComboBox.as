namespace UI {
    uint ComboBox(const string &in label, const array<string> &in items, uint v) {
        if (BeginCombo(label, items[v])) {
            for (uint i = 0; i < items.Length; i++) {
                bool selected = items[v] == items[i];
                if (Selectable(items[i], selected)) {
                    v = i;
                }
                if (selected) SetItemDefaultFocus();
            }
            EndCombo();
        }
        return v;
    }
}