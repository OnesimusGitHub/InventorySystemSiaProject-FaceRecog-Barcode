<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Register.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.Register" Async="true" UnobtrusiveValidationMode="None" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>User Registration - Face Recognition</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            box-sizing: border-box;
        }
        .btn {
            background-color: #007bff;
            color: white;
            padding: 12px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 5px;
        }
        .btn:hover {
            background-color: #0056b3;
        }
        .btn-secondary {
            background-color: #6c757d;
        }
        .btn-secondary:hover {
            background-color: #545b62;
        }
        .face-section {
            border: 2px dashed #007bff;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
            border-radius: 10px;
            background-color: #f8f9fa;
        }
        .video-container {
            position: relative;
            display: inline-block;
        }
        #video {
            width: 300px;
            height: 225px;
            border: 2px solid #007bff;
            border-radius: 10px;
            background-color: #000;
        }
        #canvas {
            display: none;
        }
        .message {
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        .short-pass-input {
            width: 80px !important;
            text-align: center;
            font-size: 18px;
            font-weight: bold;
        }
        .face-status {
            margin-top: 10px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <h2 style="text-align: center; color: #333; margin-bottom: 30px;">
                🔐 User Registration with Face Recognition
            </h2>

            <!-- Success/Error Messages -->
            <asp:Panel ID="pnlMessage" runat="server" Visible="false">
                <asp:Label ID="lblMessage" runat="server" />
            </asp:Panel>

            <!-- Registration Form -->
            <div class="form-group">
                <label for="txtName">Full Name:</label>
                <asp:TextBox ID="txtName" runat="server" CssClass="form-control" placeholder="Enter your full name" />
                <asp:RequiredFieldValidator ID="rfvName" runat="server" ControlToValidate="txtName" 
                    ErrorMessage="Name is required" ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
            </div>

            <div class="form-group">
                <label for="txtEmail">Email Address:</label>
                <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" placeholder="Enter your email" />
                <asp:RequiredFieldValidator ID="rfvEmail" runat="server" ControlToValidate="txtEmail" 
                    ErrorMessage="Email is required" ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
                <asp:RegularExpressionValidator ID="revEmail" runat="server" ControlToValidate="txtEmail"
                    ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$" ErrorMessage="Invalid email format" 
                    ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
            </div>

            <div class="form-group">
                <label for="txtPassword">Password:</label>
                <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" placeholder="Enter password (min 6 characters)" />
                <asp:RequiredFieldValidator ID="rfvPassword" runat="server" ControlToValidate="txtPassword" 
                    ErrorMessage="Password is required" ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
                <asp:RegularExpressionValidator ID="revPassword" runat="server" ControlToValidate="txtPassword"
                    ValidationExpression=".{6,}" ErrorMessage="Password must be at least 6 characters" 
                    ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
            </div>

            <div class="form-group">
                <label for="txtConfirmPassword">Confirm Password:</label>
                <asp:TextBox ID="txtConfirmPassword" runat="server" CssClass="form-control" TextMode="Password" placeholder="Confirm your password" />
                <asp:CompareValidator ID="cvPassword" runat="server" ControlToValidate="txtConfirmPassword" 
                    ControlToCompare="txtPassword" ErrorMessage="Passwords do not match" 
                    ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
            </div>

            <div class="form-group">
                <label for="txtShortPass">4-Digit Short Pass (for quick login):</label>
                <asp:TextBox ID="txtShortPass" runat="server" CssClass="form-control short-pass-input" 
                    MaxLength="4" placeholder="0000" />
                <asp:RequiredFieldValidator ID="rfvShortPass" runat="server" ControlToValidate="txtShortPass" 
                    ErrorMessage="Short pass is required" ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
                <asp:RegularExpressionValidator ID="revShortPass" runat="server" ControlToValidate="txtShortPass"
                    ValidationExpression="^\d{4}$" ErrorMessage="Short pass must be exactly 4 digits" 
                    ForeColor="Red" Display="Dynamic" EnableClientScript="false" />
                <small style="color: #666;">Enter exactly 4 digits (e.g., 1234)</small>
            </div>

            <!-- Face Recognition Section -->
            <div class="face-section">
                <h3>📷 Face Recognition Setup</h3>
                <p>Capture your face for biometric authentication (optional but recommended)</p>
                
                <div class="video-container">
                    <video id="video" autoplay muted></video>
                    <canvas id="canvas"></canvas>
                </div>
                
                <div style="margin-top: 15px;">
                    <button type="button" id="btnStartCamera" class="btn">Start Camera</button>
                    <button type="button" id="btnCapturePhoto" class="btn btn-secondary" disabled>Capture Photo</button>
                    <button type="button" id="btnRetakePhoto" class="btn btn-secondary" style="display:none;">Retake Photo</button>
                </div>
                
                <div id="faceStatus" class="face-status"></div>
                <asp:HiddenField ID="hfFaceEncoding" runat="server" />
            </div>

            <!-- Submit Button -->
            <div style="text-align: center; margin-top: 30px;">
                <asp:Button ID="btnRegister" runat="server" CssClass="btn" Text="🚀 Register Account" 
                    OnClick="btnRegister_Click" />
                <a href="Login.aspx" class="btn btn-secondary">Already have an account? Login</a>
            </div>
        </div>
    </form>

    <script>
        let video = document.getElementById('video');
        let canvas = document.getElementById('canvas');
        let context = canvas.getContext('2d');
        let stream = null;
        let photoTaken = false;

        document.getElementById('btnStartCamera').addEventListener('click', startCamera);
        document.getElementById('btnCapturePhoto').addEventListener('click', capturePhoto);
        document.getElementById('btnRetakePhoto').addEventListener('click', retakePhoto);

        async function startCamera() {
            try {
                stream = await navigator.mediaDevices.getUserMedia({ video: true });
                video.srcObject = stream;
                
                document.getElementById('btnStartCamera').disabled = true;
                document.getElementById('btnCapturePhoto').disabled = false;
                document.getElementById('faceStatus').innerHTML = '<span style="color: green;">✅ Camera started - Position your face and click Capture</span>';
            } catch (err) {
                document.getElementById('faceStatus').innerHTML = '<span style="color: red;">❌ Camera access denied or not available</span>';
                console.error('Error accessing camera:', err);
            }
        }

        function capturePhoto() {
            if (!stream) return;

            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            context.drawImage(video, 0, 0);

            // Convert to base64 (simplified face encoding)
            const imageData = canvas.toDataURL('image/jpeg', 0.8);
            const faceEncoding = btoa(imageData); // Simple encoding - replace with actual face recognition

            document.getElementById('<%= hfFaceEncoding.ClientID %>').value = faceEncoding;
            
            // Stop camera
            if (stream) {
                stream.getTracks().forEach(track => track.stop());
            }
            
            video.style.display = 'none';
            canvas.style.display = 'block';
            canvas.style.width = '300px';
            canvas.style.height = '225px';
            canvas.style.border = '2px solid green';
            canvas.style.borderRadius = '10px';

            document.getElementById('btnCapturePhoto').style.display = 'none';
            document.getElementById('btnRetakePhoto').style.display = 'inline-block';
            document.getElementById('faceStatus').innerHTML = '<span style="color: green;">✅ Photo captured successfully!</span>';
            
            photoTaken = true;
        }

        function retakePhoto() {
            video.style.display = 'block';
            canvas.style.display = 'none';
            
            document.getElementById('btnStartCamera').disabled = false;
            document.getElementById('btnCapturePhoto').disabled = true;
            document.getElementById('btnRetakePhoto').style.display = 'none';
            document.getElementById('faceStatus').innerHTML = '';
            document.getElementById('<%= hfFaceEncoding.ClientID %>').value = '';
            
            photoTaken = false;
        }

        // Short pass input formatting
        document.getElementById('<%= txtShortPass.ClientID %>').addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '').substring(0, 4);
        });

        // Cleanup on page unload
        window.addEventListener('beforeunload', function() {
            if (stream) {
                stream.getTracks().forEach(track => track.stop());
            }
        });
    </script>
</body>
</html>
