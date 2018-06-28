--[[
	This file is essentially a database of Windows messages.
	There are the standard reserved messages, those below 0x0400,
	and there are various other messages, that have become common
	by one means or another.

	For the most part the messages are taken from WinUser.h, which 
	defines them.  The ones in this file cover all Windows releases.

	The database has a 'reverse lookup' feature, which can be used to turn
	code into a string.  simply use:
		local msgs = require("wmmsgs")
		local name = msgs[0x0007];
		
		-- name == 'WM_SETFOCUS'

-- Standard Windows Messages
-- References 
-- https://wiki.winehq.org/List_Of_Windows_Messages
-- https://www.autoitscript.com/autoit3/docs/appendix/WinMsgCodes.htm
-- http://blog.airesoft.co.uk/2009/11/wm_messages/
-- WinUser.h
]]

local enum = require("enum")

local export = enum {
	WM_NULL 			= 0x0000;
	WM_CREATE 			= 0x0001;
	WM_DESTROY 			= 0x0002;
	WM_MOVE				= 0x0003;
	-- nothing for 0x0004;
	WM_SIZE 			= 0x0005;
	WM_ACTIVATE 		= 0x0006;
	WM_SETFOCUS			= 0x0007;
	WM_KILLFOCUS		= 0x0008;
	-- nothing for 0x0009;
	WM_ENABLE			= 0x000A;
	WM_SETREDRAW		= 0x000B;
	WM_SETTEXT 			= 0x000C;
	WM_GETTEXT 			= 0x000D;
	WM_GETTEXTLENGTH	= 0x000E;
	WM_PAINT			= 0x000F;
	WM_CLOSE 			= 0x0010;
	WM_QUERYENDSESSION	= 0x0011;
	WM_QUIT 			= 0x0012;
	WM_QUERYOPEN		= 0x0013;
	WM_ERASEBKGND		= 0x0014;
	WM_SYSCOLORCHANGE	= 0x0015;
	WM_ENDSESSION 		= 0x0016;
	-- nothing for 0x0017;
	WM_SHOWWINDOW		= 0x0018;
	WM_CTLCOLOR 		= 0x0019;
	WM_WININICHANGE		= 0x001A;
	WM_DEVMODECHANGE	= 0x001B;
	WM_ACTIVATEAPP 		= 0x001C;
	WM_FONTCHANGE		= 0x001D;
	WM_TIMECHANGE		= 0x001E;
	WM_CANCELMODE		= 0x001F;

	WM_SETCURSOR 		= 0x0020;
	WM_GETMINMAXINFO 	= 0x0024;

	WM_WINDOWPOSCHANGING = 0x0046;
	WM_WINDOWPOSCHANGED = 0x0047;

	-- nothing for 0x0056 - 0x007A
	
	WM_CONTEXTMENU		= 0x007B;
	WM_STYLECHANGING	= 0x007C;
	WM_STYLECHANGED		= 0x007D;
	WM_DISPLAYCHANGE	= 0x007E;
	WM_GETICON			= 0x007F;
	WM_SETICON			= 0x0080;
	WM_NCCREATE 		= 0x0081;
	WM_NCDESTROY 		= 0x0082;
	WM_NCCALCSIZE 		= 0x0083;
	WM_NCHITTEST 		= 0x0084;
	WM_NCPAINT 			= 0x0085;
	WM_NCACTIVATE 		= 0x0086;
	WM_GETDLGCODE 		= 0x0087;
	WM_SYNCPAINT 		= 0x0088;
	
	-- Metro messages from Windows 8
	WM_UAHDESTROYWINDOW = 0x0090;
	WM_UAHDRAWMENU 		= 0x0091;
	WM_UAHDRAWMENUITEM 	= 0x0092;
	WM_UAHINITMENU 		= 0x0093;
	WM_UAHMEASUREMENUITEM = 0x0094;
	WM_UAHNCPAINTMENUPOPUP = 0x0095;

-- Non Client (NC) mouse activity
	WM_NCMOUSEMOVE 		= 0x00A0;
	WM_NCLBUTTONDOWN 	= 0x00A1;
	WM_NCLBUTTONUP 		= 0x00A2;
	WM_NCLBUTTONDBLCLK 	= 0x00A3;
	WM_NCRBUTTONDOWN 	= 0x00A4;
	WM_NCRBUTTONUP 		= 0x00A5;
	WM_NCRBUTTONDBLCLK 	= 0x00A6;
	WM_NCMBUTTONDOWN 	= 0x00A7;
	WM_NCMBUTTONUP 		= 0x00A8;
	WM_NCMBUTTONDBLCLK 	= 0x00A9;
	-- nothing for 0x00AA;
	WM_NCXBUTTONDOWN	= 0x00AB;
	WM_NCXBUTTONUP		= 0x00AC;
	WM_NCXBUTTONDBLCLK	= 0x00AD;

	WM_INPUT_DEVICE_CHANGE = 0x00FE;
	WM_INPUT			= 0x00FF;

-- Keyboard Activity
	WM_KEYDOWN			= 0x0100;
	WM_KEYUP			= 0x0101;
	WM_CHAR				= 0x0102;
	WM_DEADCHAR			= 0x0103;
	WM_SYSKEYDOWN		= 0x0104;
	WM_SYSKEYUP			= 0x0105;
	WM_SYSCHAR			= 0x0106;
	WM_SYSDEADCHAR		= 0x0107;
	WM_COMMAND			= 0x0111;
	WM_SYSCOMMAND		= 0x0112;


	WM_TIMER 			= 0x0113;
	WM_HSCROLL 			= 0x0114;
	WM_VSCROLL 			= 0x0115;
	WM_INITMENU 		= 0x0116;
	WM_INITMENUPOPUP 	= 0x0117;
	WM_SYSTIMER 		= 0x0118;
	WM_MENUSELECT 		= 0x011f;
	WM_MENUCHAR 		= 0x0120;
	WM_ENTERIDLE		= 0x0121;
	WM_MENURBUTTONUP 	= 0x0122;
	WM_MENUDRAG 		= 0x0123;
	WM_MENUGETOBJECT 	= 0x0124;
	WM_UNINITMENUPOPUP 	= 0x0125;

-- client area mouse activity
	WM_MOUSEFIRST		= 0x0200;
	WM_MOUSEMOVE		= 0x0200;
	WM_LBUTTONDOWN		= 0x0201;
	WM_LBUTTONUP		= 0x0202;
	WM_LBUTTONDBLCLK	= 0x0203;
	WM_RBUTTONDOWN		= 0x0204;
	WM_RBUTTONUP		= 0x0205;
	WM_RBUTTONDBLCLK	= 0x0206;
	WM_MBUTTONDOWN		= 0x0207;
	WM_MBUTTONUP		= 0x0208;
	WM_MBUTTONDBLCLK	= 0x0209;
	WM_MOUSEWHEEL		= 0x020A;
	WM_XBUTTONDOWN		= 0x020B;
	WM_XBUTTONUP		= 0x020C;
	WM_XBUTTONDBLCLK	= 0x020D;
	WM_MOUSELAST		= 0x020D;

	WM_ENTERMENULOOP 	= 0x0211;
	WM_EXITMENULOOP 	= 0x0212;
	WM_NEXTMENU 		= 0x0213;
	WM_SIZING 			= 0x0214;
	WM_CAPTURECHANGED 	= 0x0215;
	WM_MOVING 			= 0x0216;
	WM_DEVICECHANGE 	= 0x0219;

	WM_ENTERSIZEMOVE 	= 0x0231;
	WM_EXITSIZEMOVE 	= 0x0232;
	WM_DROPFILES 		= 0x0233;

	WM_IME_SETCONTEXT 	= 0x0281;
	WM_IME_NOTIFY 		= 0x0282;

	WM_NCMOUSEHOVER		= 0x02A0;
	WM_MOUSEHOVER 		= 0x02A1;
	WM_NCMOUSELEAVE		= 0x02A2;
	WM_MOUSELEAVE		= 0x02A3;

	WM_HOTKEY			= 0x0312;

	WM_PRINT 			= 0x0317;
	WM_PRINTCLIENT		= 0x0318;
	
	WM_APPCOMMAND		= 0x0319;

	WM_THEMECHANGED		= 0x031A;

	WM_CLIPBOARDUPDATE	= 0x031D;

	WM_DWMCOMPOSITIONCHANGED  		= 0x031E;
	WM_DWMNCRENDERINGCHANGED  		= 0x031F;
	WM_DWMCOLORIZATIONCOLORCHANGED 	= 0x0320;
	WM_DWMWINDOWMAXIMIZEDCHANGE    	= 0x0321;
	WM_DWMSENDICONICTHUMBNAIL  		= 0x0323;
	WM_DWMSENDICONICLIVEPREVIEWBITMAP = 0x0326;

	-- All message numbers below 0x0400 are RESERVED
	WM_USER 			= 0x0400;

	WM_APP 				= 0x8000;
}

return export