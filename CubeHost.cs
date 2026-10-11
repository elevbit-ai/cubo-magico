// Cubo Magico 3D - host nativo Windows (WebView2)
// Criado por Joaquim Pedro de Morais Filho - j360074@hotmail.com
using System;
using System.IO;
using System.Drawing;
using System.Windows.Forms;
using System.Threading.Tasks;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace CuboMagico
{
    public class MainForm : Form
    {
        private WebView2 web;

        public MainForm()
        {
            this.Text = "Cubo Mágico 3D";
            this.BackColor = Color.FromArgb(26, 26, 36);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.ClientSize = new Size(1100, 740);
            this.MinimumSize = new Size(640, 520);

            try
            {
                string icoPath = Path.Combine(BaseDir(), "Assets", "app.ico");
                if (File.Exists(icoPath)) this.Icon = new Icon(icoPath);
            }
            catch { }

            web = new WebView2();
            web.Dock = DockStyle.Fill;
            web.DefaultBackgroundColor = Color.FromArgb(26, 26, 36);
            this.Controls.Add(web);

            this.Load += new EventHandler(OnLoad);
        }

        private static string BaseDir()
        {
            return AppDomain.CurrentDomain.BaseDirectory;
        }

        private async void OnLoad(object sender, EventArgs e)
        {
            try
            {
                string userData = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "CuboMagico", "WebView2");
                Directory.CreateDirectory(userData);

                CoreWebView2Environment env = await CoreWebView2Environment.CreateAsync(null, userData, null);
                await web.EnsureCoreWebView2Async(env);

                CoreWebView2 core = web.CoreWebView2;
                core.Settings.AreDevToolsEnabled = false;
                core.Settings.AreDefaultContextMenusEnabled = false;
                core.Settings.IsStatusBarEnabled = false;
                core.Settings.IsZoomControlEnabled = false;

                string webDir = Path.Combine(BaseDir(), "web");
                core.SetVirtualHostNameToFolderMapping(
                    "cubomagico.local", webDir, CoreWebView2HostResourceAccessKind.Allow);

                core.Navigate("https://cubomagico.local/index.html");
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Não foi possível iniciar o componente de exibição (WebView2)." + Environment.NewLine +
                    "Verifique se o Runtime do Microsoft Edge WebView2 está instalado." + Environment.NewLine +
                    Environment.NewLine + ex.Message,
                    "Cubo Mágico 3D", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
