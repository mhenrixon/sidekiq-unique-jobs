export function navigate(elementId) {
  const tabGroups = document.querySelectorAll('.tab-groups');

  for (var i = 0; i < tabGroups.length; i++) {
    var txtValue = tabGroups[i].attributes.name.value;
    if (txtValue.indexOf(elementId) > -1) {
      tabGroups[i].style.display = '';
    } else {
      tabGroups[i].style.display = 'none';
    }
  }
}

window.navigate = navigate;
