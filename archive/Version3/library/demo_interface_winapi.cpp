// AUTOGEN START
// Auto-generated C++ WinAPI GUI code from HTML sketch
std::vector<GuiElement*> elements;
int y = 10;
// Label: Nom: for input input1
auto edit_input1 = new GuiEdit(L"John Doe", 101); elements.push_back(edit_input1); edit_input1->Create(parent, 10, 10, 200, 24); y += 30;
// Label: Mot de passe: for password pass1
auto pass_pass1 = new GuiEdit(L"", 102, true); elements.push_back(pass_pass1); pass_pass1->Create(parent, 10, 10, 200, 24); y += 30;
// Label: Activer for checkbox check1
auto check_check1 = new GuiCheckBox(L"check1", 103); elements.push_back(check_check1); check_check1->Create(parent, 10, 10, 100, 24); y += 30;
// Label: Choix A for radio radioA
auto radio_radioA = new GuiRadioButton(L"radioA", 104, 10, 10, 100, 24); elements.push_back(radio_radioA); radio_radioA->Create(parent); y += 30;
// Label: Choix B for radio radioB
auto radio_radioB = new GuiRadioButton(L"radioB", 105, 10, 10, 100, 24); elements.push_back(radio_radioB); radio_radioB->Create(parent); y += 30;
// Label: Valeur: for slider slider1
auto slider_slider1 = new GuiSlider(106, 0, 100, 50); elements.push_back(slider_slider1); slider_slider1->Create(parent, 10, 10, 200, 24); y += 30;
// AUTOGEN END

// MANUAL CODE BLOCK (should be preserved)
void CustomManualFunction() {
    // This function is outside AUTOGEN markers and should not be overwritten.
    printf("Manual code block is safe!\n");
}