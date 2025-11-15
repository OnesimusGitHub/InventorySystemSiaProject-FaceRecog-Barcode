.table-container {
    background: white;
    border-radius: 16px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.10);
    overflow: hidden;
    margin-bottom: 32px;
}
.table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 15px;
    background: #fff;
    border-radius: 12px;
    overflow: hidden;
}
.table thead {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
}
.table th {
    padding: 18px 16px;
    text-align: left;
    font-weight: 700;
    font-size: 15px;
    letter-spacing: 0.5px;
    border-bottom: 2px solid #ececec;
}
.table td {
    padding: 16px 16px;
    border-bottom: 1px solid #f0f0f0;
    font-size: 15px;
    background: #fff;
    vertical-align: middle;
}
.table tbody tr:nth-child(even) td {
    background: #f7f7fa;
}
.table tbody tr:hover td {
    background: #e9f0fb;
    transition: background 0.2s;
}
.table tbody tr:last-child td {
    border-bottom: none;
}
.table td button, .table td .btn {
    font-size: 13px;
    padding: 7px 14px;
    border-radius: 6px;
    margin-right: 4px;
}
.table td .btn-warning {
    background: #ffc107;
    color: #333;
    border: none;
}
.table td .btn-danger {
    background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
    color: white;
    border: none;
}
.table td .btn-warning:hover {
    background: #ffb300;
}
.table td .btn-danger:hover {
    background: #b71c1c;
}
.table th:first-child, .table td:first-child {
    border-top-left-radius: 12px;
}
.table th:last-child, .table td:last-child {
    border-top-right-radius: 12px;
}
