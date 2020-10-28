import {MDCTextField} from '@material/textfield';
import {MDCTextFieldHelperText} from '@material/textfield/helper-text';

const textFields = document.querySelectorAll('.mdc-text-field');
const helperTexts = document.querySelectorAll('.mdc-text-field-helper-text');

for (var a = 0; a < textFields.length; a++) {
  new MDCTextField(textFields[a]);
}

for (var b = 0; b < helperTexts.length; b++) {
  new MDCTextFieldHelperText(helperTexts[b]);
}
