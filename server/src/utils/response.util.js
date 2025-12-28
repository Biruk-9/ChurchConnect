function success(res, data = null, message = 'OK', status = 200) {
	res.status(status).json({ success: true, message, data });
}

function error(res, status = 400, message = 'Error', details = null) {
	res.status(status).json({ success: false, message, details });
}

module.exports = { success, error };
