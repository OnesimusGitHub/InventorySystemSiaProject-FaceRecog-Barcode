<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.Login" Async="true" UnobtrusiveValidationMode="None" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Login - Face Recognition System</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background:  #DEC7C4;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            position: relative;
            overflow: hidden;
        }
        
        /* Animated background shapes */
        body::before {
            content: '';
            position: absolute;
            width: 400px;
            height: 400px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            top: -200px;
            right: -200px;
            animation: float 6s ease-in-out infinite;
        }
        
        body::after {
            content: '';
            position: absolute;
            width: 300px;
            height: 300px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 50%;
            bottom: -150px;
            left: -150px;
            animation: float 8s ease-in-out infinite reverse;
        }
        
        @keyframes float {
            0%, 100% { transform: translateY(0) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(5deg); }
        }
        
        .login-container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 50px 45px;
            border-radius: 25px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 450px;
            width: 100%;
            position: relative;
            z-index: 1;
            animation: slideUp 0.6s ease-out;
        }
        
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .login-header h2 {
            color: #2d3748;
            margin: 0 0 12px 0;
            font-size: 32px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }
        
        .login-header p {
            color: #718096;
            font-size: 15px;
            margin: 0;
        }
        
        .form-group {
            margin-bottom: 25px;
            position: relative;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 10px;
            font-weight: 600;
            color: #2d3748;
            font-size: 14px;
            letter-spacing: 0.3px;
        }
        
        .form-group input {
            width: 100%;
            padding: 15px 20px;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-size: 15px;
            transition: all 0.3s ease;
            background-color: #f7fafc;
        }
        
        .form-group input:focus {
            border-color: #667eea;
            outline: none;
            background-color: white;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
            transform: translateY(-2px);
        }
        
        .form-group input::placeholder {
            color: #a0aec0;
        }
        
        .btn {
            width: 100%;
            background: #C97B7B;
            color: white;
            padding: 16px;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 700;
            transition: all 0.3s ease;
            margin-top: 10px;
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
            letter-spacing: 0.5px;
        }
        
        .btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 15px 35px rgba(102, 126, 234, 0.4);
        }
        
        .btn:active {
            transform: translateY(-1px);
        }
        
        .btn-secondary {
            background: linear-gradient(135deg, #718096 0%, #4a5568 100%);
            box-shadow: 0 10px 25px rgba(113, 128, 150, 0.3);
        }
        
        .btn-secondary:hover {
            box-shadow: 0 15px 35px rgba(113, 128, 150, 0.4);
        }
        
        .short-pass-input {
            text-align: center;
            font-size: 28px;
            font-weight: bold;
            letter-spacing: 12px;
        }
        
        .message {
            padding: 15px 20px;
            margin: 20px 0;
            border-radius: 12px;
            text-align: center;
            font-weight: 500;
            font-size: 14px;
        }
        
        .success {
            background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%);
            color: #155724;
            border: 2px solid #b1dfbb;
        }
        
        .error {
            background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%);
            color: #721c24;
            border: 2px solid #f1aeb5;
        }
        
        .info {
            background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%);
            color: #0c5460;
            border: 2px solid #abdde5;
        }
        /* Hidden sections */
        .login-methods {
            display: none !important;
        }
        .face-recognition-section {
            display: none !important;
            margin-top:15px;
        }
        #loginVideo { width:260px; border:2px solid #fff; border-radius:10px; box-shadow:0 4px 12px rgba(0,0,0,.25); display:block; margin:0 auto 10px; }
        #loginCanvas { display:none; }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.6);
            backdrop-filter: blur(5px);
            animation: fadeIn 0.3s ease;
        }
        
        .modal-content {
            background: rgba(255, 255, 255, 0.98);
            backdrop-filter: blur(10px);
            margin: 10% auto;
            padding: 40px;
            border-radius: 25px;
            width: 90%;
            max-width: 420px;
            text-align: center;
            box-shadow: 0 25px 70px rgba(0, 0, 0, 0.4);
            animation: modalSlideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
            position: relative;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes modalSlideIn {
            from { 
                transform: translateY(-80px) scale(0.9);
                opacity: 0;
            }
            to { 
                transform: translateY(0) scale(1);
                opacity: 1;
            }
        }
        
        .modal-header {
            margin-bottom: 25px;
        }
        
        .modal-header h3 {
            color: #2d3748;
            margin: 0;
            font-size: 28px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .user-info {
            background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
            padding: 20px;
            border-radius: 15px;
            margin: 25px 0;
            border: 2px solid #e2e8f0;
        }
        
        .user-info h4 {
            margin: 0 0 8px 0;
            color: #667eea;
            font-size: 20px;
            font-weight: 700;
        }
        
        .user-info p {
            margin: 0;
            color: #718096;
            font-size: 14px;
        }
        
        .close-modal {
            position: absolute;
            right: 20px;
            top: 20px;
            width: 36px;
            height: 36px;
            background: rgba(113, 128, 150, 0.1);
            border-radius: 50%;
            color: #718096;
            font-size: 24px;
            font-weight: bold;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
            line-height: 1;
        }
        
        .close-modal:hover {
            background: rgba(113, 128, 150, 0.2);
            color: #2d3748;
            transform: rotate(90deg) scale(1.1);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="login-container">
            <div class="login-header">
                <h2>SheEssentials Admin Login</h2>
                <p style="color: #666; margin: 10px 0 0 0;">Enter your credentials to continue</p>
            </div>

            <!-- Success/Error Messages -->
            <asp:Panel ID="pnlMessage" runat="server" Visible="false">
                <asp:Label ID="lblMessage" runat="server" />
            </asp:Panel>

            <!-- Face Recognition Section -->
            <div class="face-recognition-section">
                <video id="loginVideo" autoplay muted playsinline style="display: none;"></video>
                <canvas id="loginCanvas" style="display: none;"></canvas>
                <asp:HiddenField ID="hfFaceLoginEncoding" runat="server" />
                <asp:HiddenField ID="hfRecognizedUserId" runat="server" />
                <asp:Button ID="btnFaceLogin" runat="server" Text="Process Face Recognition" 
                    OnClick="btnFaceLogin_Click" style="display: none;" />
            </div>

            <!-- Email/Password Login -->
            <div class="form-group">
                <label for="txtEmail">Email Address:</label>
                <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" 
                    placeholder="Enter your email address" />
            </div>

            <div class="form-group">
                <label for="txtPassword">Password:</label>
                <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" 
                    placeholder="Enter your password" />
            </div>

            <asp:Button ID="btnEmailLogin" runat="server" CssClass="btn" Text="Login" 
                OnClick="btnEmailLogin_Click" />
        </div>

        <!-- Short Pass Modal -->
        <div id="shortPassModal" class="modal">
            <div class="modal-content">
                <span class="close-modal" onclick="closeShortPassModal()">&times;</span>
                <div class="modal-header">
                    <h3>✅ Face Recognized!</h3>
                </div>
                <div class="user-info">
                    <h4 id="recognizedUserName">Welcome back!</h4>
                    <p id="recognizedUserEmail"></p>
                </div>
                <div class="form-group">
                    <label for="txtModalShortPass">Enter your 4-digit PIN to continue:</label>
                    <asp:TextBox ID="txtModalShortPass" runat="server" CssClass="form-control short-pass-input" 
                        MaxLength="4" placeholder="0000" />
                </div>
                <asp:Button ID="btnModalShortPassLogin" runat="server" CssClass="btn" Text="Complete Login" 
                    OnClick="btnModalShortPassLogin_Click" />
                <button type="button" class="btn btn-secondary" onclick="closeShortPassModal()">Cancel</button>
            </div>
        </div>

        <!-- Hidden fields for backward compatibility -->
        <asp:TextBox ID="txtEmailShort" runat="server" style="display: none;" />
        <asp:TextBox ID="txtShortPassLogin" runat="server" style="display: none;" />
        <asp:Button ID="btnShortPassLogin" runat="server" style="display: none;" OnClick="btnShortPassLogin_Click" />
    </form>

    <script>
        let loginVideo = document.getElementById('loginVideo');
        let loginCanvas = document.getElementById('loginCanvas');
        let loginContext = loginCanvas.getContext('2d');
        let loginStream = null;
        let faceRecognitionInterval = null;
        let isProcessingFace = false;
        let loginSuccessful = false; // Add flag to track successful login

        // Global functions for face recognition
        window.showShortPassModal = function(userName, userEmail, userId) {
            document.getElementById('recognizedUserName').textContent = userName;
            document.getElementById('recognizedUserEmail').textContent = userEmail;
            document.getElementById('<%= hfRecognizedUserId.ClientID %>').value = userId;
            document.getElementById('shortPassModal').style.display = 'block';
            document.getElementById('<%= txtModalShortPass.ClientID %>').focus();
            stopFaceRecognition();
        };

        window.closeShortPassModal = function() {
            if (!loginSuccessful) { // Only restart if login wasn't successful
                document.getElementById('shortPassModal').style.display = 'none';
                document.getElementById('<%= txtModalShortPass.ClientID %>').value = '';
                document.getElementById('<%= hfRecognizedUserId.ClientID %>').value = '';
                setTimeout(startFaceRecognition, 500);
            }
        };

        window.faceRecognitionFailed = function() {
            if (!loginSuccessful) {
                isProcessingFace = false;
            }
        };

        // Function to mark login as successful and stop all face recognition
        window.markLoginSuccessful = function() {
            loginSuccessful = true;
            stopFaceRecognition();
            document.getElementById('shortPassModal').style.display = 'none';
        };

        // Auto-start face recognition when page loads
        window.addEventListener('load', function() {
            if (!loginSuccessful) {
                setTimeout(startFaceRecognition, 1000);
            }
        });

        async function startFaceRecognition() {
            if (loginSuccessful) return;
            
            try {
                loginStream = await navigator.mediaDevices.getUserMedia({ video: true });
                loginVideo.srcObject = loginStream;
                faceRecognitionInterval = setInterval(captureAndRecognizeFace, 5000);
            } catch (err) {
                // Face recognition not available - silent fail
            }
        }

        function stopFaceRecognition() {
            if (loginStream) {
                loginStream.getTracks().forEach(track => track.stop());
                loginStream = null;
            }
            if (faceRecognitionInterval) {
                clearInterval(faceRecognitionInterval);
                faceRecognitionInterval = null;
            }
            isProcessingFace = false;
        }

        function captureAndRecognizeFace(force=false) {
            if (!loginStream || !loginVideo.videoWidth || isProcessingFace || loginSuccessful) return;
            const now = Date.now();
            if(!force){
                if(window._lastSent && now - window._lastSent < 3000) { return; }
            }
            isProcessingFace = true;
            loginCanvas.width = loginVideo.videoWidth;
            loginCanvas.height = loginVideo.videoHeight;
            loginContext.drawImage(loginVideo, 0, 0);

            const imageData = loginCanvas.toDataURL('image/jpeg', 0.8);
            if (imageData.length < 15000) { isProcessingFace=false; return; }

            const faceEncoding = btoa(imageData);
            document.getElementById('<%= hfFaceLoginEncoding.ClientID %>').value = faceEncoding;
            window._lastSent = now;
            document.getElementById('<%= btnFaceLogin.ClientID %>').click();
        }

        // Short pass input formatting
        document.addEventListener('DOMContentLoaded', function() {
            const shortPassInput = document.getElementById('<%= txtModalShortPass.ClientID %>');
            if (shortPassInput) {
                shortPassInput.addEventListener('input', function(e) {
                    this.value = this.value.replace(/[^0-9]/g, '').substring(0, 4);
                    if (this.value.length === 4) {
                        setTimeout(() => {
                            document.getElementById('<%= btnModalShortPassLogin.ClientID %>').click();
                        }, 500);
                    }
                });
            }

            // Initial focus on email
            const emailInput = document.getElementById('<%= txtEmail.ClientID %>');
            if (emailInput) {
                emailInput.focus();
            }
        });

        // Enter key handling
        document.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                const modal = document.getElementById('shortPassModal');
                if (modal && modal.style.display === 'block') {
                    document.getElementById('<%= btnModalShortPassLogin.ClientID %>').click();
                } else {
                    document.getElementById('<%= btnEmailLogin.ClientID %>').click();
                }
            }
        });

        // Cleanup on page unload
        window.addEventListener('beforeunload', function() {
            stopFaceRecognition();
        });

        // Close modal when clicking outside
        window.addEventListener('click', function(event) {
            const modal = document.getElementById('shortPassModal');
            if (event.target === modal && !loginSuccessful) {
                window.closeShortPassModal();
            }
        });

        // Close modal function for onclick events
        function closeShortPassModal() {
            window.closeShortPassModal();
        }

        // Alternative redirect function in case the above doesn't work
        window.redirectToDashboard = function() {
            window.location.replace('Dashboard.aspx');
        };

        // Manual capture for testing
        window.manualCapture = function() {
            const testButton = document.querySelector('button[onclick="manualCapture()"]');
            testButton.innerText = 'Capturing...';
            testButton.disabled = true;
            setTimeout(() => {
                testButton.innerText = 'Test Capture';
                testButton.disabled = false;
            }, 3000);
        };
    </script>
</body>
</html>
