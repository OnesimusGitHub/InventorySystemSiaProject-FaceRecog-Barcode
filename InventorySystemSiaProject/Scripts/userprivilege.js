(function(){
    var mediaStream=null;
    window.closeEditUser=function(){var m=document.getElementById('editUserModal'); if(m) m.style.display='none'; stopCamera();};
    window.startCamera=function(){
        var v=document.getElementById('faceVideo');
        if(!navigator.mediaDevices||!navigator.mediaDevices.getUserMedia){updateFaceStatus('Camera API not supported',true);return;}
        navigator.mediaDevices.getUserMedia({video:true}).then(function(stream){mediaStream=stream;v.srcObject=stream;updateFaceStatus('Camera started');})
            .catch(function(err){updateFaceStatus('Camera error: '+err.message,true);});
    };
    window.stopCamera=function(){if(mediaStream){mediaStream.getTracks().forEach(function(t){t.stop();});mediaStream=null;updateFaceStatus('Camera stopped');}};
    window.captureFace=function(){
        var v=document.getElementById('faceVideo');
        if(!v||!v.srcObject){updateFaceStatus('Camera not running',true);return;}
        var c=document.getElementById('faceCanvas');
        var ctx=c.getContext('2d');
        c.width=320;c.height=240;ctx.drawImage(v,0,0,320,240);
        var dataUrl=c.toDataURL('image/png');
        var img=document.getElementById('faceSnapshot'); if(img){img.src=dataUrl; img.style.display='block';}
        var encoding = sha256(dataUrl.substring(dataUrl.indexOf(',')+1));
        try{document.getElementById(window.faceEncodingId).value=encoding; document.getElementById(window.faceHashId).value=encoding.substring(0,32); var snap=document.getElementById(window.editFaceSnapshotId); if(snap) snap.value=dataUrl;}catch(e){}
        updateFaceStatus('Face captured & encoding generated');
    };
    // === Add User Camera Functions (were missing) ===
    var mediaStreamAdd=null;
    window.startCameraAdd=function(){
        var v=document.getElementById('faceVideoAdd');
        if(!navigator.mediaDevices||!navigator.mediaDevices.getUserMedia){updateFaceStatusAdd('Camera API not supported',true);return;}
        navigator.mediaDevices.getUserMedia({video:true}).then(function(stream){mediaStreamAdd=stream;v.srcObject=stream;updateFaceStatusAdd('Camera started');})
            .catch(function(err){updateFaceStatusAdd('Camera error: '+err.message,true);});
    };
    window.stopCameraAdd=function(){if(mediaStreamAdd){mediaStreamAdd.getTracks().forEach(function(t){t.stop();});mediaStreamAdd=null;updateFaceStatusAdd('Camera stopped');}};
    window.captureFaceAdd=function(){
        var v=document.getElementById('faceVideoAdd');
        if(!v||!v.srcObject){updateFaceStatusAdd('Camera not running',true);return;}
        var c=document.getElementById('faceCanvasAdd');
        var ctx=c.getContext('2d');
        c.width=320;c.height=240;ctx.drawImage(v,0,0,320,240);
        var dataUrl=c.toDataURL('image/png');
        var img=document.getElementById('faceSnapshotAdd'); if(img){img.src=dataUrl; img.style.display='block';}
        // Switch context to add fields
        window.faceEncodingId = window.addFaceEncodingId;
        window.faceHashId = window.addFaceHashId;
        var encoding = sha256(dataUrl.substring(dataUrl.indexOf(',')+1));
        try{document.getElementById(window.faceEncodingId).value=encoding; document.getElementById(window.faceHashId).value=encoding.substring(0,32); var snap=document.getElementById(window.addFaceSnapshotId); if(snap) snap.value=dataUrl;}catch(e){}
        updateFaceStatusAdd('Face captured & encoding generated');
    };
    function updateFaceStatus(msg,isError){var el=document.getElementById('faceStatus'); if(!el) return; el.textContent=msg; el.className='status-text '+(isError?'error':'');}
    function updateFaceStatusAdd(msg,isError){var el=document.getElementById('faceStatusAdd'); if(!el) return; el.textContent=msg; el.className='status-text '+(isError?'error':'');}
    // Minimal SHA-256 implementation (same as inline version)
    function sha256(str){function r(n,x){return(x>>>n)|(x<<(32-n));}var H=[1779033703,-1150833019,1013904242,-1521486534,1359893119,-1694144372,528734635,1541459225];var K=[1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298];var msg=unescape(encodeURIComponent(str));var l=msg.length*8;var M=[];for(var i=0;i<msg.length;i++){M[i>>2]|=msg.charCodeAt(i)<<(24-(i&3)*8);}M[l>>5]|=0x80<<(24-(l&31));M[((l+64>>9)<<4)+15]=l;for(var i=0;i<M.length;i+=16){var W=M.slice(i,i+16);for(var j=16;j<64;j++){W[j]=(r(7,W[j-15])^r(18,W[j-15])^(W[j-15]>>>3))+W[j-16]+(r(17,W[j-2])^r(19,W[j-2])^(W[j-2]>>>10))+W[j-7]|0;}var a=H[0],b=H[1],c=H[2],d=H[3],e=H[4],f=H[5],g=H[6],h=H[7];for(var j=0;j<64;j++){var S1=r(6,e)^r(11,e)^r(25,e);var ch=(e&f)^(~e&g);var t1=h+S1+ch+K[j]+W[j]|0;var S0=r(2,a)^r(13,a)^r(22,a);var maj=(a&b)^(a&c)^(b&c);var t2=S0+maj|0;h=g;g=f;f=e;e=d+t1|0;d=c;c=b;b=a;a=t1+t2|0;}H[0]=H[0]+a|0;H[1]=H[1]+b|0;H[2]=H[2]+c|0;H[3]=H[3]+d|0;H[4]=H[4]+e|0;H[5]=H[5]+f|0;H[6]=H[6]+g|0;H[7]=H[7]+h|0;}var hex='';for(var i=0;i<8;i++){hex+=('00000000'+(H[i]>>>0).toString(16)).slice(-8);}return hex;}
})();
(function(){
    function normalize(s){return (s||'').toString().toLowerCase();}
    function getUserTable(){return document.querySelector('table.user-table');}
    function applyClientFilter(){
        var searchBox=document.querySelector('.toolbar-input');
        var roleSelect=document.querySelector('.toolbar-select');
        var tbl=getUserTable();
        if(!tbl){return;} // nothing to filter yet
        var term=normalize(searchBox?searchBox.value:'')
        var role=normalize(roleSelect?roleSelect.value:'')
        var body=tbl.tBodies[0]; if(!body) return;
        Array.prototype.forEach.call(body.rows,function(r){
            var name=normalize(r.cells[0].textContent);
            var email=normalize(r.cells[1].textContent);
            var roleVal=normalize(r.cells[2].textContent);
            var matchTerm = !term || name.indexOf(term)>-1 || email.indexOf(term)>-1;
            var matchRole = !role || roleVal===role;
            r.style.display = (matchTerm && matchRole)?'':'none';
        });
    }
    function wireFilter(){
        var searchBox=document.querySelector('.toolbar-input');
        var roleSelect=document.querySelector('.toolbar-select');
        if(searchBox){ searchBox.addEventListener('keyup', applyClientFilter); }
        if(roleSelect){ roleSelect.addEventListener('change', applyClientFilter); }
        document.addEventListener('click', function(e){ if(e.target.getAttribute('data-action')==='search'){ applyClientFilter(); }});
    }
    if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded', function(){wireFilter(); applyClientFilter();});}else{wireFilter(); applyClientFilter();}
    window.applyUserClientFilter=applyClientFilter;
})();
(function(){
    // IDs from root data attributes
    var root=document.getElementById('userPageRoot');
    if(root){
        window.editFaceEncodingId = root.getAttribute('data-edit-face-encoding-id');
        window.editFaceHashId = root.getAttribute('data-edit-face-hash-id');
        window.addFaceEncodingId = root.getAttribute('data-add-face-encoding-id');
        window.addFaceHashId = root.getAttribute('data-add-face-hash-id');
        window.addFaceSnapshotId = root.getAttribute('data-add-face-snapshot-id');
        window.editFaceSnapshotId = root.getAttribute('data-edit-face-snapshot-id');
    }
    function show(el){ if(el){ el.style.display='flex'; el.style.visibility='visible'; el.style.opacity='1'; } }
    function hide(el){ if(el){ el.style.display='none'; } }
    function qs(id){ return document.getElementById(id); }

    // Explicit function for fallback (can be called from markup if needed)
    window.openAddUserModal = function(){
        try { window.faceEncodingId=window.addFaceEncodingId; window.faceHashId=window.addFaceHashId; } catch(_){}
        console.log('[UserPrivilege] Opening Add User modal');
        show(qs('addUserModal'));
    };

    // Improved event delegation (supports clicks on child elements)
    document.addEventListener('click', function(e){
        var node = e.target.closest('[data-action]');
        if(!node) return;
        var act = node.getAttribute('data-action');
        switch(act){
            case 'open-add-user': openAddUserModal(); break;
            case 'close-add': hide(qs('addUserModal')); if(window.stopCameraAdd) stopCameraAdd(); break;
            case 'close-edit': hide(qs('editUserModal')); if(window.stopCamera) stopCamera(); break;
            case 'start-edit-cam': if(window.startCamera) startCamera(); break;
            case 'stop-edit-cam': if(window.stopCamera) stopCamera(); break;
            case 'capture-edit-face': if(window.captureFace) captureFace(); break;
            case 'start-add-cam': if(window.startCameraAdd) startCameraAdd(); break;
            case 'stop-add-cam': if(window.stopCameraAdd) stopCameraAdd(); break;
            case 'capture-add-face': if(window.captureFaceAdd) captureFaceAdd(); break;
        }
    });
})();