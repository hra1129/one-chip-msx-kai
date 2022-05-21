
namespace OcmKeymapper {
	partial class Form1 {
		/// <summary>
		/// 必要なデザイナー変数です。
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// 使用中のリソースをすべてクリーンアップします。
		/// </summary>
		/// <param name="disposing">マネージド リソースを破棄する場合は true を指定し、その他の場合は false を指定します。</param>
		protected override void Dispose( bool disposing ) {
			if( disposing && ( components != null ) ) {
				components.Dispose();
			}
			base.Dispose( disposing );
		}

		#region Windows フォーム デザイナーで生成されたコード

		/// <summary>
		/// デザイナー サポートに必要なメソッドです。このメソッドの内容を
		/// コード エディターで変更しないでください。
		/// </summary>
		private void InitializeComponent() {
			this.label1 = new System.Windows.Forms.Label();
			this.comboBoxKeyboardLayoutNumber = new System.Windows.Forms.ComboBox();
			this.label2 = new System.Windows.Forms.Label();
			this.SuspendLayout();
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(16, 16);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(96, 12);
			this.label1.TabIndex = 0;
			this.label1.Text = "Keyboard Layout#";
			// 
			// comboBoxKeyboardLayoutNumber
			// 
			this.comboBoxKeyboardLayoutNumber.FormattingEnabled = true;
			this.comboBoxKeyboardLayoutNumber.Location = new System.Drawing.Point(132, 11);
			this.comboBoxKeyboardLayoutNumber.Name = "comboBoxKeyboardLayoutNumber";
			this.comboBoxKeyboardLayoutNumber.Size = new System.Drawing.Size(162, 20);
			this.comboBoxKeyboardLayoutNumber.TabIndex = 1;
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(16, 60);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(117, 12);
			this.label2.TabIndex = 0;
			this.label2.Text = "MSX Keyboard Layout";
			// 
			// Form1
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(1095, 818);
			this.Controls.Add(this.comboBoxKeyboardLayoutNumber);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.label1);
			this.Name = "Form1";
			this.Text = "OCM-PLD/OCM-Kai Key Mapper";
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.ComboBox comboBoxKeyboardLayoutNumber;
		private System.Windows.Forms.Label label2;
	}
}

