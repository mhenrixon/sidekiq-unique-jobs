import {MDCDataTable} from '@material/data-table';
new MDCDataTable(document.querySelector('.mdc-data-table'));

export function searchTable(elementId) {
  const input = document.getElementById(elementId);
  const filter = input.value.toUpperCase();
  const table = document.getElementById(elementId + '-table');
  const rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');

  for (var i = 0; i < rows.length; i++) {
    var row = rows[i].getElementsByTagName('td')[0];
    var txtValue = row.textContent || row.innerText;
    if (txtValue.toUpperCase().indexOf(filter) > -1) {
      rows[i].style.display = '';
    } else {
      rows[i].style.display = 'none';
    }
  }
}

window.searchTable = searchTable;

function sortTable(table, col, reverse) {
  var tb = table.tBodies[0];
  var tbh = table.tHead;
  var th = Array.prototype.slice.call(tbh.rows, 0);
  var tr = Array.prototype.slice.call(tb.rows, 0);
  var i;
  var c;
  reverse = -((+reverse) || -1);
  tr = tr.sort(function(a, b) {
    return reverse * a.cells[col].dataset.sortVal.localeCompare(
      b.cells[col].dataset.sortVal, undefined, {numeric: true},
    );
  });
  for (i = 0; i < th.length; ++i) {
    for (c = 0; c < th[i].cells.length; ++c) {
      if (c != col) {
        th[i].cells[c].childNodes[1].classList.add('hide');
        th[i].cells[c].childNodes[3].classList.add('hide');
      } else {
        if (reverse == 1) {
          th[i].cells[c].childNodes[1].classList.add('hide');
          th[i].cells[c].childNodes[3].classList.remove('hide');
        } else {
          th[i].cells[c].childNodes[1].classList.remove('hide');
          th[i].cells[c].childNodes[3].classList.add('hide');
        }
      }
    }
  }
  for (i = 0; i < tr.length; ++i) tb.appendChild(tr[i]);
}

function makeSortable(table) {
  var th = table.tHead;
  var i;
  th && (th = th.rows[0]) && (th = th.cells);
  if (th) i = th.length;
  else return;
  while (--i >= 0) {
    (function(i) {
      var dir = 1;
      th[i].addEventListener('click', function() {
        sortTable(table, i, (dir = 1 - dir));
      });
    }(i));
  };
}

function makeAllSortable(parent) {
  parent = parent || document.body;
  var t = parent.getElementsByTagName('table');
  var i = t.length;
  while (--i >= 0) {
    makeSortable(t[i]);
  };
}

function defaultSort() {
  var t = document.getElementsByTagName('table');
  var i;
  for (i = 0; i < t.length; ++i) {
    sortTable(t[i], 1, -1);
  }
}

window.onload = function() {
  makeAllSortable();
  defaultSort();
};
