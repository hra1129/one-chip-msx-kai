		default:	ff_dbi <= 8'hxx;
		endcase
	end

	assign dbi = ff_dbi;
endmodule
